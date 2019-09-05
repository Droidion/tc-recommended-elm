"use strict";

require("./styles.scss");

const basePath = new URL(document.baseURI).pathname;

const { Elm } = require("./Main");
var app = Elm.Main.init({
    flags: basePath
});
