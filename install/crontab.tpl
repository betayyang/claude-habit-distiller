# claude-habit-distiller — daily habit distillation
# Runs every day at __HOUR__:__MINUTE__. Installed by install.sh on Linux.
__MINUTE__ __HOUR__ * * * PATH=__PATH__ /bin/bash __RUN_SH__ >> __SKILL_DIR__/cron.log 2>&1
