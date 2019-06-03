if [ -z "$1" ]; then
  echo "Missing 'version' as first parameter";
  exit 1;
fi
RELEASE=$1
echo "About to make release $RELEASE ..."
./create_jlink_image.sh
echo "Custom Runtime Image created."
zip -r $RELEASE.zip custom_jre
zip -r $RELEASE.zip target/modulepath/
cp run_locally.sh run.sh
zip $RELEASE.zip run.sh
echo "Release $RELEASE successfully created."

