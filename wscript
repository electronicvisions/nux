#!/usr/bin/python


def depends(dep):
    if getattr(dep.options, 'with_s2pp_tests', True):
        dep('s2pp', 'tests/instructions')


def options(opt):
    hopts = opt.add_option_group('s2pp options')
    hopts.add_withoption('s2pp-tests', default=True,
                         help='Toggle the build of s2pp instruction tests.')


def configure(cfg):
    pass


def build(bld):
    pass
