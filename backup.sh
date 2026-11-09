#!/bin/bash
set -e # выходим при ошибке

#========== 0. Переменные и подготовка

SOURCE_ROOT="/mnt/workdisk"

SSH_KEY="/mnt/workdisk/tools/ssh/debian-pve"
SSH_USER="debian@192.168.0.104"
SSH_COMMAND () { ssh -i "$SSH_KEY" "$SSH_USER" "$@" ; }

DEST_ROOT="/mnt/backups/workdisk"


# Создаём папку, если её не существует
if ! SSH_COMMAND "[ -d '$DEST_ROOT' ]"; then SSH_COMMAND "mkdir -p $DEST_ROOT"; fi

# =========================================

# Функция получения даты и времени
DATETIME () { date "+%Y-%m-%d_%H-%M" ; }


# Создаём папку с датой для бэкапа на сервере
DEST_DATE="${DEST_ROOT}/$(DATETIME)"
# Важно: $ при вызове функций нужен лишь в том случае, если мы хотим работать с её выводом как текстом, а при её вызове с аргументами не требуется

SSH_COMMAND "mkdir -p '${DEST_DATE}'"



# Создаём лог-файл в папке назначения
LOG_FILE="${DEST_DATE}/$(DATETIME).log"
SSH_COMMAND touch "$LOG_FILE"


# Функция для логирования
LOG_WRITE () {

  # Переменные-аргументы + дата и время с секундами
  local LOG_STATUS="$1"
  local LOG_TEXT="$2"

  # Сама команда + вызов даты
  echo -e "[$LOG_STATUS] [$(date '+%d.%m.%Y %H:%M:%S')] $LOG_TEXT" | SSH_COMMAND "cat >> $LOG_FILE"

}

LOG_WRITE "INFO" "Создана папка назначения $DEST_DATE и лог-файл $(DATETIME).log"

# Папки, подлежащие копированию
COPYDIRS=("genealogy" "notes")

# Выводим список папок
( IFS=', '; LOG_WRITE "INFO" "Папки для копирования из $SOURCE_ROOT: ${COPYDIRS[*]}" ) 



# ========= 2. Архивация

for COPYDIR in "${COPYDIRS[@]}"; do
  ROOT_COPYDIR="${SOURCE_ROOT}/${COPYDIR}"
  if [ -d "${ROOT_COPYDIR}" ]; then
    LOG_WRITE "BACKUP" "Копируется папка: ${COPYDIR}"
    tar -cz -C "${ROOT_COPYDIR}" . | SSH_COMMAND "cat > '${DEST_DATE}/${COPYDIR}.tar.gz'"
    LOG_WRITE "BACKUP" "Скопирована папка: ${COPYDIR}"
  else LOG_WRITE "WARNING" "Не найдена папка: ${COPYDIR}. Пропуск..."
  fi
done

DEST_DATE_SIZE="$(SSH_COMMAND du -sh ${DEST_DATE} | awk '{print $1}')"
LOG_WRITE "FINISH" "Папки скопированы. Размер бэкапа: ${DEST_DATE_SIZE}"
