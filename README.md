## Policy Central 2.0

Initial client side build for the new unified Insight policy management application.

### Development

The default branch is `master`. Tagged releases should be built from master once all changes have been pull requested and merged. Day to day development should happen on the `develop` branch, or for larger projects, create a separate feature branch.

### Deployment

Production ready assets should be delivered as a tagged release build to the DevOps team. When a git [tag](http://git-scm.com/book/en/Git-Basics-Tagging) is created and pushed to Github, a Jenkins job is triggered that, among other things, optimizes the JavaScript modules with `r.js`, minifies the various assets, and appends the tag version to the Policy Central footer. The easiest way to trigger this Jenkins job is to draft a new release [here](https://github.com/icg360/policy-central/releases). Note: you can also run this job locally via `rake build`, which will create a compiled, minified version of Policy Central with the latest version appended to the footer in a directory named `build`. Make sure you have the latest tags locally by issuing a `git pull` from the command line.

### Dependencies

* __JavaScript Libraries__
	* jQuery
	* Require.js
	* Underscore.js (AMD Flavor)
	* Backbone.js (AMD Flavor)
	* Amplify.js (AMD Flavor)

NodeJS dependencies are handled by NPM (`$ sudo npm -g install`) via
the package.json file

* __Node.js Libraries__
	* RequireJS (if you want to use the r.js optimizations w/Node)
	* UglifyJS2 (for Require Optimizations)
	* CoffeeScript
    * JSHint (stay clean!)

Ruby dependencies are handled by Bundler (`$ gem install bundler;
bundle install`) via the Gemfile.

* __Ruby Libraries__
	* Rake
	* Bundler
	* Compass / SASS / CSS3-Pie (requires an Apache header)
	* Susy
    * Nokogiri
    * Foreman

### Use Foreman to manage your dev watchers

When developing you can use Foreman to run the Compass and Cake
watchers, which will in turn autocompile your Sass and Coffee files
while you work:

`$ foreman start -f Procfile.dev`

### Rake is your friend

Rake will build the production ready deliverable for you. Jenkins uses
this to create the zip for deployment. To build the project:

`$ rake build`

This will compile everything, and also concat and uglify all of the
compiled JavaScript files via the RequireJS rules in
`source/js/app.build.js`.

Everything will be dumped in `build` and version numbers (taken from
the most recent Git tag) will be added to the compiled files.

### Special note about IPM Forms

All of the HTML templates for Policy Management (IPM) are found in `/source/js/modules/IPM/products`. You will get many tickets to update these forms, and you will be tempted to modify them within this repo. **You do so at your peril, and this way lies only madness.** You should make all changes to IPM templates in the [ipm-toolchain](https://github.com/icg360/ipm-toolchain) repo and then copy over the built folders to this one. In fact, there's a [rake task](https://github.com/icg360/ipm-toolchain/blob/master/Rakefile#L42) to help you do just that.

**ipm-toolchain** is the canonical source for the HTML/JSON IPM files. Additionally, the ICS team is the canonical source of data for the insurance products and therefore it is incumbent upon them to maintain up-to-date versions of their Excel files. This warning has been given, heed as you will.

That said, `/sources/coffee/modules/IPM/actions` contains all of the `.coffee` files to handling IPM actions such as Endorse. These are the "logic" behind the actions and reside in this repo. 

### Browser Compatability List

* Firefox 12+
* Chrome
* Safari 5+
* NO SUPPORT FOR IE (Because CORS)
