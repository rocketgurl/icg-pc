## Policy Central 2.0

Initial client side build for the new unified Insight policy management application.

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

All of the HTML templates for Policy Management (IPM) are found in `/source/js/modules/IPM/products`. You will get many tickets to update these forms, and you will be tempted to modify them within this repo. **You do so at your peril, and this way lies only madness.** You should make all changes to IPM templates in the [ipm-toolchain](https://github.com/icg360/ipm-toolchain) repo and then copy over the built folders to this one.

**ipm-toolchain** is the canonical source for the HTML/JSON IPM files. Additionally, the ICS team is the canonical source of data for the insurance products and therefore it is incumbent upon them to maintain up-to-date versions of their Excel files. This warning has been given, heed as you will.

That said, `/sources/coffee/modules/IPM/actions` contains all of the `.coffee` files to handling IPM actions such as Endorse. These are the "logic" behind the actions and reside in this repo. 

### Browser Compatability List

* Firefox 12+
* Chrome
* Safari 5+
* NO SUPPORT FOR IE (Because CORS)
