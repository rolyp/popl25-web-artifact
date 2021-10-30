Many thanks for your efforts in evaluating our artifact; we very much appreciate this. We respond to your questions below and have updated our artifact and instructions. We have also created tag `v0.4.1` in GitHub (https://github.com/explorable-viz/fluid/tree/v0.4.1) which permanently references the (corrected) version of the artifact, and updated the artifact evaluation instructions to point to this.

**Note:** To make it possible to edit tests locally and have the changes be visible inside the Docker container, we now ask you to mount the repository as an external folder when the Docker `run` command is issued. This means the application build and deployments steps (e.g. `yarn install`) are no longer part of the Dockerfile (because the repository is unavailable when the image is built). Please follow the updated instructions for running the web and and tests provided in `artifact-evaluation.md`.

> 1. The web app does not display several bar charts as mentioned in the artifact-evaluation.md under Step 1. I can only see the one corresponding to Fig.2 (I am using Chrome on Ubuntu). In fact, the web page itself does not speak about Fig.1 at all.

Sorry about this. In the process of editing the final HTML, it seems we accidentally deleted the `div` tag used to insert the figure into the DOM. We have restored this; if you update your local copy of the repository to the corrected version and rebuild the web server, you should now see the additional raw images required for Fig. 1.

We also supplied the missing explanation of how the generated images relate to Fig. 1, and added section headings (one for each of figures 2, 1 and 13) to make the page easier to read. (The section for Fig. 1 follows Fig. 2 because one of the Fig. 2 images is reused as part of Fig. 1.)

Finally, we updated `artifact-evaluation.md` to state that there should be three bar charts, rather than "several".

> 2. Are the visualizations meant to be interactive? If that is indeed the case, I am also not able to do that beyond 'hovering' over the bars. This may be related to my confusion regarding question 1 above.

These figures are not intended to be interactive, although d3.js adds tooltips to the bar charts automatically. We added clarifying text to the web page to set expectations appropriately. Sorry for not being clear about this.

> 3. Is it the case that the test files have .fld format and the expected outputs have .expect.fld format?

Correct. We have updated the "Additional artifact description" section of `artifact-evaluation.md` accordingly.

> 4. With the answer to 3 above, how do I run an individual test? The artifact-evaluation.md document often refers to the instructions above for running the test suite, but those instructions only pertain to running the entire suite, rather than individual tests.

Running individual tests is possible but requires a small amount of manual effort. We have added a new section to `artifact-evaluation.md` entitled "Running individual tests" which details how to do this. As an example of how this works, and to assist you with Step 4 of the evaluation, we have configured things so that `test_scratchpad` initially contains just the two tests associated with `section-5-example`.

> 5. I would like to run each test and render the visualizations, as opposed to running the tests in headless mode. If I am not mistaken, this would be required to carry out Step 4 as described in the artifact-evalaution.md

Step 4 of the evaluation can still be run in headless mode; in fact none of the tests generate images as outputs, and so any of them can be run in headless mode. (The images are generated by the web app, not the tests.)

If you wish to experiment with the `section-5-example` tests, you may prefer to the run the tests individually, using the new instructions alluded to above. For example, to verify that these tests do indeed generate output consistent with the expectations provided in `section-5-example-1.expect` and `section-5-example-2.expect`, you can edit these files manually, and check that the tests fail. (While you can also do this by running the entire test suite, it will be quicker just to run `test_scratchpad` with these two tests enabled.) Fig. 16 was generated generated by hand, with the LaTeX `listings` package, using these outputs.