Author: James Laderoute
Created: 2/11/2022


This folder stores all the successful runs of what you are testing.
That way, you can compare the most recent run against the last working run.

If you are creating a new test and do not yet have a golden file, then I 
would suggest that you run the script anyways. It won't be able to do a
successful diff because it's missing the golden file; but what you can
do now is copy the most recent log file into the golden directory.

Retest (re run the script) again and now it should not have a failure
due to having a missing golden file.

If the test fails, then you need to investigate why it failed and fix
the issue. If the failure was because you introduced a different output
only and you deem it is ok; then just copy your current log into the
golden directory.

If the test fails for real, for example you have a bug in the code; then
of course you should fix the bug and re-run the test again to make sure
it still passes against the golden file. You shouldn't need to create a
new golden file in this case unless you fixed a bug and that fix 
produces ligitimate but different output.

Note: If you are wondering why our logs have the extension of .out instead
of .log; it is because our git configuration file ignores files that
end in .log

