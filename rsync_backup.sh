#!/bin/bash
# Rsync incremental and rotating backups to a local folder or ssh location
#
# USAGE: rsync_backup.sh launch_file
#
# This is the core script, you should not touch it.
# All the backup settings are made in a dedicated launch_file


function dst_request {
# Effectue une requete sur la destination
local RESULT
if [ ${SERVER_IP} ]
then # Destination SHH
  RESULT=$( ssh ${LOGIN}@${SERVER_IP} -i ${RSA_KEY} -p ${PORT} "eval ${1}" )
else # Destination locale
  RESULT=$( eval ${1} )
fi
echo ${RESULT}
}


function sauvegarde {

# Effectue une sauvegarde

#1- DEFINITION DE LA SAUVEGARDE COURANTE
TODAY_BACKUP="${DST_PTH}${SRC_FLD}_`date -I`"
echo "Dossier source : ${SRC_PTH}${SRC_FLD}"
echo "Dossier de destination : ${TODAY_BACKUP}"

#2- RECHERCHE DE LA DERNIERE SAUVEGARDE
CMD="ls -1dr ${DST_PTH}${SRC_FLD}_* 2>/dev/null | head -1"
LAST_BACKUP=$(dst_request "${CMD}")
if [ -z ${LAST_BACKUP} ]
then # Pas de sauvegarde anterieure
  DUMMY_BACKUP="${DST_PTH}${SRC_FLD}_2000-01-01"
  LAST_BACKUP="${DUMMY_BACKUP}"
  dst_request "mkdir $DUMMY_BACKUP 2>/dev/null"
  echo "Derniere sauvegarde effectuee : AUCUNE"
elif [ $LAST_BACKUP = $TODAY_BACKUP ]
then # Une sauvegarde a deja ete effectue aujourd'hui
  echo "ERREUR: Une sauvegarde de ce dossier a deja ete effectuee aujourd'hui !"
  exit 1
else # Il y a une ou plusieurs sauvegardes anterieures
  echo "Derniere sauvegarde effectuee : $LAST_BACKUP"
fi
# Creation du dossier de sauvegarde
if [ $SIMULATION = 0 ]; then dst_request "mkdir -p $TODAY_BACKUP" ;fi

#3- COMMANDE RSYNC
OPTIONS="${DRYRUN_OPTION} -H -h -v --stats -r -tgo -p -l -D --delete-after --delete-excluded"
if [ -z ${SERVER_IP} ]
then # Sauvegarde locale
  rsync ${OPTIONS} ${EXCLUDE} --link-dest=${LAST_BACKUP} "${SRC_PTH}${SRC_FLD}/" "${TODAY_BACKUP}/"  > ${LOG}
else # Sauvegarde SSH
  rsync ${OPTIONS} ${EXCLUDE} -e "ssh -i ${RSA_KEY} -p ${PORT}" --link-dest=${LAST_BACKUP} "${SRC_PTH}${SRC_FLD}/" "${LOGIN}@${SERVER_IP}:${TODAY_BACKUP}/"  > ${LOG}
fi

# 4- NETTOYAGE DU LOG
sed -e '/ file.../d' -e '/\/$/d' ${LOG} > ~/.log
mv ~/.log ${LOG}


# 5- EFFACEMENT DES VIEILLES SAUVEGARDES
if [ ${DUMMY_BACKUP} ]
then # Premiere sauvegarde 
  dst_request "rm -rf ${DUMMY_BACKUP}"
elif [ ${SIMULATION} = 0 ]
then # Effacement des sauvegardes anterieurs
  CMD="find ${DST_PTH}${SRC_FLD}_* -maxdepth 0 -type d -ctime +$HOLD"
  OLD_FLD=$(dst_request "${CMD}")
  dst_request "rm -rf ${OLD_FLD}"
  if [ ${OLD_FLD} ]; then
    echo "Sauvegarde(s) effacee(s): ${OLD_FLD}"
	echo ""
  fi
fi

echo "Emplacement du rapport complet: ${LOG}"
echo "  $(grep "Number of files:" ${LOG})"
echo "  $(grep "Total file size" ${LOG})"
echo "  $(grep "Number of files transferred:" ${LOG})"
echo "  $(grep "bytes/sec" ${LOG})"
}


function restauration {
# Effectue une restauration
echo "Mode restauration non disponible pour l'instant !"
exit 1
}


# MAIN CODE
source ${1}
EXCLUDE="${EXCLUDE}"" --exclude=*~ \
                      --exclude=*Thumbs.db \
                      --exclude=.DS_Store"
echo ""

#1- MODE SIMULATION
if [ ${SIMULATION} = 1 ] ; then
  DRYRUN_OPTION="--dry-run"
  echo "-- MODE SIMULATION -- (Aucune donnee ne sera copiee ou effacee)"
elif [ ${SIMULATION} = 0 ] ; then
  DRYRUN_OPTION=""
fi

#2- SELECTION DU PROCESSUS
if [ $# = 1 ]; then
  if [ -z ${SERVER_IP} ]; then 
    echo "Initialisation d'une sauvegarde sur l'arborescence locale"; else
    echo "Initialisation d'une sauvegarde sur ${LOGIN}@${SERVER_IP}:${PORT}"
  fi
  echo "Les sauvegardes anterieures a $HOLD jours seront effacees"
  sauvegarde
else 
  if [ -z ${SERVER_IP} ]; then
    echo "Initialisation d'une restauration depuis l'arborescence locale"; else
    echo "Initialisation d'une restauration depuis ${LOGIN}@${SERVER_IP}:${PORT}"
  fi
	restauration
fi

echo ""
