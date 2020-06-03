from __future__ import annotations

import random
import unittest
from typing import Set
from collections import namedtuple
import re
import os
from dlens_vx.hxcomm import ManagedConnection
from dlens_vx.sta import run, generate, DigitalInit
from dlens_vx.halco import PPUOnDLS, iter_all
from dlens_vx.tools.run_ppu_program import load_and_start_program, \
    stop_program, wait_until_ppu_finished, PPUTimeoutError
from dlens_vx import logger

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
    MANAGED_CONNECTION = ManagedConnection()
    CONNECTION = None

    @classmethod
    def setUpClass(cls) -> None:
        # Connect to some executor (sim or hardware)
        cls.CONNECTION = cls.MANAGED_CONNECTION.__enter__()
        # Initialize the chip
        init_builder, _ = generate(DigitalInit())
        run(cls.CONNECTION, init_builder.done())

    @classmethod
    def tearDownClass(cls) -> None:
        # Disconnect the executor
        cls.MANAGED_CONNECTION.__exit__()

    @classmethod
    def generate_cases(cls):
        """
        Augment this class by test cases for all tests defined in `cls.TESTS`.
        """
        for test in cls.TESTS:
            def generate_test(ppu_test: PpuHwTest):
                def test_func(self: S2PPInstructionTestsHwSimVx):
                    log = logger.get("S2PPInstructionTestsHwSimVx.%s" %
                                     ppu_test.name)
                    ppu = random.choice(list(iter_all(PPUOnDLS)))
                    log.info("Running test on %s." % ppu)

                    load_and_start_program(cls.CONNECTION, ppu_test.path, ppu)
                    try:
                        wait_until_ppu_finished(cls.CONNECTION,
                                                timeout=int(1e4),
                                                ppu=ppu)
                    except PPUTimeoutError:
                        self.fail(
                            "Test did not go to sleep -> indicating failure.")
                    finally:
                        # s2pp instruction tests do not use the mailbox
                        stop_program(cls.CONNECTION, print_mailbox=False,
                                     ppu=ppu)
                return test_func
            test_method = generate_test(test)
            test_method.__name__ = test.name
            setattr(cls, test.name, test_method)

    @classmethod
    def find_binaries(cls):
        test_regex = re.compile(r'.*\.bin$')
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
