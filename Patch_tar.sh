#! /bin/bash

ORIG_BRANCH=`git branch | grep '*' | awk '{print $2}'`
CURRENT_PWD=`pwd`
PROJECT_BASE_DIR=`basename $CURRENT_PWD | tr 'a-z' 'A-Z'`
TARTGET_PATCH_DIR="${PROJECT_BASE_DIR}_patch_tar"

if [[ $# > 1 ]]; then
	NEW_COMMIT=$1
	BASE_COMMIT=$2
	if [ -n "$3" ]; then
		TARTGET_PATCH_DIR=${3}_patch
	fi
	echo "base commit is $2, new commit is $1, target patch directory is ${TARTGET_PATCH_DIR}"
else
	NEW_COMMIT=HEAD
	BASE_COMMIT=HEAD^
	echo "use $BASE_COMMIT as base commit and $NEW_COMMIT as new commit, or you can $0 [[NEW_COMMIT] [BASE_COMMIT]] [TARTGET_PATCH_DIR]"
fi

cd $CURRENT_PWD

CURRENT_STATUS=`git status -suno`

if [ -n "$CURRENT_STATUS" ]; then
	git stash >/dev/null 2>&1
fi

rm -Rf ${TARTGET_PATCH_DIR} ${TARTGET_PATCH_DIR}.tar.gz ; 
mkdir -p ${TARTGET_PATCH_DIR}/new && 
mkdir -p ${TARTGET_PATCH_DIR}/old && 
git branch -D for_patch_tar_old for_patch_tar_new >/dev/null 2>&1 ; 
git branch for_patch_tar_old $BASE_COMMIT && 
git branch for_patch_tar_new $NEW_COMMIT && 
git checkout for_patch_tar_new  >/dev/null 2>&1 && 
git diff --name-only for_patch_tar_old for_patch_tar_new | xargs tar caf ${TARTGET_PATCH_DIR}/new/for_patch_tar_new.tar.gz && 
git checkout for_patch_tar_old  >/dev/null 2>&1 && 
git diff --name-only for_patch_tar_old for_patch_tar_new | xargs tar caf ${TARTGET_PATCH_DIR}/old/for_patch_tar_old.tar.gz && 
cd ${TARTGET_PATCH_DIR}/old && 
tar xaf for_patch_tar_old.tar.gz && 
rm for_patch_tar_old.tar.gz &&  
cd ../new && 
tar xaf for_patch_tar_new.tar.gz && 
rm for_patch_tar_new.tar.gz && 
cd ../.. && 
tar caf ${TARTGET_PATCH_DIR}.tar.gz ${TARTGET_PATCH_DIR}

if [ "$?" = "0" ]; then
	echo "produce ${TARTGET_PATCH_DIR}.tar.gz done"
else
	echo "produce patch file fail"
fi

git checkout $ORIG_BRANCH >/dev/null 2>&1
git branch -D for_patch_tar_new for_patch_tar_old >/dev/null 2>&1
if [ -n "$CURRENT_STATUS" ]; then
	git stash pop  >/dev/null 2>&1
fi




