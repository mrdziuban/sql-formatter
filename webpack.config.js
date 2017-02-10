const webpack = require('webpack');
const merge = require('webpack-merge');
const path = require('path');
const CleanWebpackPlugin = require('clean-webpack-plugin');
const CopyWebpackPlugin = require('copy-webpack-plugin');
const ExtractTextPlugin = require('extract-text-webpack-plugin');
const WriteFilePlugin = require('write-file-webpack-plugin');

module.exports = function(env) {
  const prod = env && env.production;

  const base = {
    entry: path.join(__dirname, 'js', 'index.js'),
    output: {
      path: path.join(__dirname, 'dist'),
      publicPath: path.join(__dirname, 'dist', path.sep),
      filename: path.join('js', 'bundle.js'),
      sourceMapFilename: '[file].map'
    },
    module: {
      rules: [
        {
          test: /\.elm$/,
          exclude: [/elm-stuff/, /node_modules/],
          loader: 'elm-webpack-loader?pathToMake=node_modules/.bin/elm-make&warn=true&yes=true'
        },
        {
          test: /\.scss$/,
          loader: ExtractTextPlugin.extract({
            fallback: 'style-loader',
            use: `css-loader?minimize=${prod ? 'true' : 'false'}&sourceMap=true&url=false!sass-loader?sourceMap=true`
          })
        }
      ]
    },
    plugins: [
      new CopyWebpackPlugin([
        { from: path.join(__dirname, 'index.html'), to: path.join(__dirname, 'dist', 'index.html') },
        { from: path.join(__dirname, 'img'), to: path.join(__dirname, 'dist', 'img') }
      ]),
      new ExtractTextPlugin(path.join('css', 'bundle.css'))
    ]
  };

  return Object.defineProperty(merge(base,
    prod ? {
      plugins: [
        new CleanWebpackPlugin([path.join(__dirname, 'dist')], { verbose: true }),
        new webpack.optimize.UglifyJsPlugin({
          compress: { screw_ie8: true, warnings: false },
          mangle: true,
          output: { comments: false },
          sourceMap: true
        })
      ]
    } : {
      devtool: '#source-map',
      devServer: {
        contentBase: path.join(__dirname, 'dist', path.sep),
        historyApiFallback: true,
        port: 8000
      },
      plugins: [new WriteFilePlugin()]
    }), 'outputPath', { enumerable: false, value: path.join(__dirname, 'dist', path.sep) });
};
