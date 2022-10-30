#!/bin/sh

set -e

# activate venv
. $BINGE_PATH/.venv/bin/activate

# run binge
python /binge/binge.py | /binge/vector --config-toml /binge/vector.toml
