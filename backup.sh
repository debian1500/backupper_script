#!/bin/bash
set -e # выходим при ошибке

#========== 0. Переменные и подготовка

SOURCE_ROOT="/mnt/workdisk"
#SOURCE_BASENAME="$(basename $SOURCE_ROOT)"
SSH_KEY="/mnt/workdisk/tools/ssh/debian-pve"
SSH_USER="debian@192.168.0.104"
SSH_COMMAND="ssh -i $SSH_KEY $SSH_USER"
#SCP_R_COMMAND="scp -r -i $SSH_KEY"

DEST_ROOT="/mnt/backups/workdisk"

# Проверяем наличие папки на сервере и создаём при её отсутствии
if ! $SSH_COMMAND "[ -d '$DEST_ROOT' ]"; then $SSH_COMMAND "mkdir -p $DEST_ROOT"; fi

# Важное примечание
# Здесь в проверке папки используется сочетание двойных ("") и одинарных ('') кавычек.
# В случае с SSH, они работают "вместе" - удалённый сервер воспримет имя переменной не как буквальный текст (типа '$имя_переменной'), так как "выше по званию" именно двойные кавычки, через которые переменные передаются нормально.
# А воспримет именно как 'имя_папки' - это нужно для правильной обработки сложных имён папок.
# В случае с локальным использованием, такое не сработает, и достаточно обойтись двойными кавычками.

# Создаём лог-файл в нашей папке

# Команда для получения даты и времени по шаблону
DATENAME () { date "+%Y-%m-%d_%H-%M" }
# Запоминаем текущую дату и время на моAмент запуска и пишем в переменную
DATE_CURRENT="$(DATENAME)"
DATE_SECS () { date "+%Y-%m-%d_%H-%M-%S"  }

# ========== 1. Папки
# Создаём временную папку для бэкапа на локальном ПК
# mkdir -p "/tmp/${SOURCE_BASENAME}_backup/${DATE_CURRENT}"


# Создаём папку с датой для бэкапа на сервере
DEST_DATE="${DEST_ROOT}/${DATE_CURRENT}"
$SSH_COMMAND "mkdir -p '${DEST_DATE}'"


# Создаём лог-файл в папке назначения
DEST_LOG="${DEST_DATE}/${DATE_CURRENT}.log"
#DEST_LOG_BASENAME="$(basename "$DEST_LOG")"
$SSH_COMMAND "touch '$DEST_LOG'"

echo -e "[START] $(DATE_SECS) Создана папка назначения $DEST_DATE и лог-файл ${DATE_CURRENT}.log" | $SSH_COMMAND "cat >> "$DEST_LOG"

# Папки, подлежащие копированию
COPYDIRS=(
"documents"
)

echo -e "[INFO] Папки для копирования:\n" >> "$DEST_LOG"

for COPYDIR in "$COPYDIRS" do echo -e "  ${SOURCE_ROOT}/${COPYDIR}\n" >>"$DEST_LOG"; done 


# ========= 2. Архивация
#
echo 
for COPYDIR in "${COPYDIRS[@]}"; do
  ROOT_COPYDIR="${SOURCE_ROOT}/${COPYDIR}"
  if [ -d "${ROOT_COPYDIR}" ]; then
    tar -cJ -C "${ROOT_COPYDIR}" . | $SSH_COMMAND "cat > '${DEST_DATE}/${COPYDIR}.tar.xz'"
  else echo "" # Выводим в пустоту
  fi
done

