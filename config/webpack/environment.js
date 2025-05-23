const { environment } = require('@rails/webpacker')
const sassLoader = environment.loaders.get('sass')
const cssLoader = sassLoader.use.find(loader => loader.loader === 'css-loader')

cssLoader.options = Object.assign(cssLoader.options, {
  modules: {
    localIdentName: '[path][name]__[local]--[hash:base64:5]'
  }
})

// Configure Babel loader to exclude D3 modules from transpilation
const babelLoader = environment.loaders.get('babel')
const originalExclude = babelLoader.exclude
babelLoader.exclude = [
  ...(Array.isArray(originalExclude) ? originalExclude : [originalExclude]),
  /node_modules\/d3.*/
].filter(Boolean)

module.exports = environment
