#!/usr/bin/env bash

julia -e 'import Pkg; Pkg.add("LocalRegistry"); using LocalRegistry; register();'
