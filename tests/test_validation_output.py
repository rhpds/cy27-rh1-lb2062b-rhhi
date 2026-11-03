"""Check validation feedback using a temporary local Ansible target."""

import os
import re
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ANSIBLE = shutil.which("ansible-playbook")


def run_playbook(playbook, *, env=None, extra_vars=None, cwd=None):
    command = [ANSIBLE, "-i", "rhel,", "-c", "local", str(playbook)]
    for key, value in (extra_vars or {}).items():
        command.extend(["-e", f"{key}={value}"])
    return subprocess.run(
        command,
        cwd=cwd,
        env={**os.environ, "ANSIBLE_NOCOLOR": "1", "ANSIBLE_LOCAL_TEMP": "/tmp/ansible-rhhi-b-test", **(env or {})},
        capture_output=True,
        text=True,
        timeout=90,
        check=False,
    )


@unittest.skipUnless(ANSIBLE, "ansible-playbook is not installed")
class ValidationOutputTests(unittest.TestCase):
    def setUp(self):
        temp = tempfile.TemporaryDirectory(prefix="rhhi-b-validation-")
        self.addCleanup(temp.cleanup)
        self.root = Path(temp.name)

    def runtime_tree(self, script):
        runtime = self.root / "runtime"
        runtime.mkdir()
        wrapper = (ROOT / "runtime-automation/main.yml").read_text()
        # The temporary local host does not require root privileges.
        (runtime / "main.yml").write_text(wrapper.replace("          become: true\n", "          become: false\n"))
        module = runtime / "example"
        module.mkdir()
        (module / "validation-rhel.sh").write_text(script)
        output = self.root / "job"
        output.mkdir()
        return runtime, output

    def run_runtime(self, runtime, output):
        return run_playbook(
            runtime / "main.yml",
            cwd=runtime,
            env={"BASTION_HOST": "rhel", "BASTION_PORT": "22"},
            extra_vars={"module_dir": "example", "module_stage": "validation", "job_info_dir": output},
        )

    def test_multiline_markdown_is_preserved_in_job_output(self):
        message = (
            "**Validation incomplete:** Image `rhhi-demo:builder` was not found.\n\n"
            "Review **“Switch to the Builder Variant”** in Module 2, then validate again."
        )
        runtime, output = self.runtime_tree(
            "#!/bin/sh\nset -e\nfail_validation - <<'EOF'\n" + message + "\nEOF\n"
        )
        result = self.run_runtime(runtime, output)
        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual((output / "validation_failure.out").read_text(), message)
        self.assertIn("= FAIL VALIDATION BEGIN", (output / "script.out").read_text())

    def test_success_has_no_validation_failure(self):
        runtime, output = self.runtime_tree("#!/bin/sh\necho validated\n")
        result = self.run_runtime(runtime, output)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("validated", (output / "script.out").read_text())
        self.assertFalse((output / "validation_failure.out").exists())

    def test_unmarked_failure_is_not_shown_as_validation_feedback(self):
        runtime, output = self.runtime_tree("#!/bin/sh\necho 'internal error' >&2\nexit 2\n")
        result = self.run_runtime(runtime, output)
        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertFalse((output / "validation_failure.out").exists())

    def test_qa_message_does_not_leak_to_following_stage(self):
        qa = self.root / "qa"
        tasks = qa / "tasks"
        tasks.mkdir(parents=True)
        shutil.copy(ROOT / "qa-automation/tasks/run_script.yml", tasks / "run_script.yml")
        module = self.root / "example"
        module.mkdir()
        (module / "validation-rhel.sh").write_text("#!/bin/sh\nset -e\nfail_validation 'Missing SBOM'\n")
        playbook = qa / "test.yml"
        playbook.write_text(
            "---\n- hosts: rhel\n  gather_facts: false\n  vars:\n"
            f"    runtime_path: {self.root}\n"
            "    module_name: example\n  tasks:\n"
            "    - block:\n"
            "        - ansible.builtin.include_tasks: tasks/run_script.yml\n"
            "          vars:\n            stage_name: validation\n"
            "      rescue:\n"
            "        - ansible.builtin.include_tasks: tasks/run_script.yml\n"
            "          vars:\n            stage_name: setup\n"
            "        - ansible.builtin.assert:\n"
            "            that: _validation_failure == ''\n"
        )
        result = run_playbook(playbook)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("Missing SBOM", result.stdout)

    def test_scripts_are_posix_syntax_and_section_references_exist(self):
        scripts = list((ROOT / "runtime-automation").glob("module-*/*-rhel.sh"))
        for script in scripts:
            syntax = subprocess.run(["sh", "-n", str(script)], capture_output=True, text=True)
            self.assertEqual(syntax.returncode, 0, f"{script}: {syntax.stderr}")
            for line in script.read_text().splitlines():
                if not line.startswith("Review ") and '"Review ' not in line:
                    continue
                match = re.search(r"in Module (\d+)", line)
                self.assertIsNotNone(match, f"{script}: {line}")
                pages = list((ROOT / "content/modules/ROOT/pages").glob(f"module-{int(match[1]):02d}-*.adoc"))
                self.assertEqual(len(pages), 1, f"{script}: Module {match[1]}")
                headings = {
                    re.sub(r"\s+", " ", heading).strip()
                    for heading in re.findall(r"^={1,3}\s+(.*)$", pages[0].read_text(), re.M)
                }
                for section in re.findall(r"\*\*“([^”]+)”\*\*", line):
                    self.assertIn(section, headings, f"{script}: Module {match[1]}: {section}")


if __name__ == "__main__":
    unittest.main()