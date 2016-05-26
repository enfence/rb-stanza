#!/usr/bin/ruby

# Stanza Class
# This file is a part of rb-stanza library
#
# Author::    Andrey Klyachkin <andrey.klyachkin@enfence.com>
# Copyright:: Copyright (c) 2016 eNFence GmbH
# License::   Apache-2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# The module Stanza has two classes:
# * Stanza
# * StanzaFile
module Stanza
    # :nodoc:
    VERSION = "0.0.2"

    autoload :Stanza, 'Stanza/Stanza'
    autoload :StanzaFile, 'Stanza/StanzaFile'

end
