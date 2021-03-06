# Copyright 2019 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"Shared fixtures."

import os

import pytest
import tftest


_BASEDIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


@pytest.fixture(scope='session')
def plan():

  def run_plan(testdir):
    tfdir = testdir.replace('_', '-')
    tf = tftest.TerraformTest(tfdir, _BASEDIR,
                              os.environ.get('TERRAFORM', 'terraform'))
    tf.setup(extra_files=['tests/{}/terraform.tfvars'.format(testdir)])
    return tf.plan(output=True)

  return run_plan
