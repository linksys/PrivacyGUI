echo "*********************Generating Localization snapshots********************"
flutter test --tags=loc --update-goldens
echo 'Generating Localization snapshots Finished!******************************************'

# copy all screenshots to "screenshots" folder
mkdir ./snapshots/
for dir in $(find ./ -iname 'goldens' -type d); do
  echo $dir
  find "$dir" -type f -exec cp {} ./snapshots/ \;
done