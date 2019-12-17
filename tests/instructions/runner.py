from __future__ import annotations
import unittest
from typing import Set
from collections import namedtuple
import re
import os
from dlens_vx.sta import PlaybackProgramExecutor, generate, DigitalInit
from dlens_vx.tools.run_ppu_program import load_and_start_program, \
    stop_program, wait_until_ppu_finished, PPUTimeoutError

_THIS_DIR = os.path.dirname(os.path.realpath(__file__))
TEST_BINARY_PATH = os.environ.get("TEST_BINARY_PATH",
                                  os.path.join(_THIS_DIR,
                                               os.pardir,
                                               os.pardir,
                                               os.pardir,
                                               "build",
                                               "s2pp",
                                               "tests",
                                               "instructions"))
if not os.path.isdir(TEST_BINARY_PATH):
    raise RuntimeError(f"s2pp test binary folder ({TEST_BINARY_PATH}) "
                       f"does not exist!")
PpuHwTest = namedtuple("PpuHwTest", ["path", "name"])


class S2PPInstructionTestsHwSimVx(unittest.TestCase):
    TESTS: Set[PpuHwTest] = set()
    EXECUTOR = PlaybackProgramExecutor()

    @classmethod
    def setUpClass(cls) -> None:
        # Connect to some executor (sim or hardware)
        cls.EXECUTOR.connect()
        # Initialize the chip
        init_builder, _ = generate(DigitalInit())
        cls.EXECUTOR.run(init_builder.done())

    @classmethod
    def tearDownClass(cls) -> None:
        # Disconnect the executor
        cls.EXECUTOR.disconnect()

    @classmethod
    def generate_cases(cls):
        """
        Augment this class by test cases for all tests defined in `cls.TESTS`.
        """
        for test in cls.TESTS:
            def generate_test(ppu_test: PpuHwTest):
                def test_func(self: S2PPInstructionTestsHwSimVx):
                    load_and_start_program(cls.EXECUTOR, ppu_test.path)
                    try:
                        wait_until_ppu_finished(cls.EXECUTOR,
                                                timeout=int(1e4))
                    except PPUTimeoutError:
                        self.fail(
                            "Test did not go to sleep -> indicating failure.")
                    finally:
                        stop_program(cls.EXECUTOR)
                return test_func
            test_method = generate_test(test)
            test_method.__name__ = test.name
            setattr(cls, test.name, test_method)

    @classmethod
    def find_binaries(cls):
        test_regex = re.compile(r'.*\.binary')
        for path, _, files in os.walk(TEST_BINARY_PATH):
            for fname in files:
                if test_regex.search(fname):
                    binary_path = os.path.realpath(os.path.join(path, fname))
                    cls.TESTS.add(PpuHwTest(
                        name=unittest.TestLoader.testMethodPrefix
                        + os.path.splitext(fname)[0],
                        path=binary_path))


S2PPInstructionTestsHwSimVx.find_binaries()
S2PPInstructionTestsHwSimVx.generate_cases()

if __name__ == '__main__':
    unittest.main()
