# 1.1.0

* Added working GitHub publish workflow
* Added http override to example project
* Fixed #1 by adding an "EXAM" PeriodState and a default case
* The "exam" field is now accessible via UntisExam
* getExam() now delivers much more information as UntisExam now contains much more fields (when getExam() is used)
* Fixed bug that caused every request for times in october on the 10th day of month to fail
* You can now actually use an arbitrary time range (the start date just needs to be before the end date). I mistakenly
  wrote a check whether the start date lies after the end date. This is now fixed

# 1.0.2 (not on pub.dev)

* Fixed README.md's formatting
* Made example project functional
* Bumped dependencies

# 1.0.1

* Changed GitHub workflow automation

# 1.0.0

* Initial development release.
