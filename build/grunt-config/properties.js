/*jshint node:true */


module.exports = {
	//set to `true` when paired with Phing
	buildOnly: false,
    htmlRenderEngine: 'jade', //jade or render
	viewmatch: '*.{html,jade}' // for php projects use: '*.{html,php,phtml}'
};