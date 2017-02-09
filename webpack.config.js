const webpack = require('webpack');
const merge = require('webpack-merge');
const path = require('path');

module.exports = function(env) {
  const prod = env && env.production;

  const base = {
    entry: path.join(__dirname, 'index.js'),
    output: {
      filename: 'bundle.js',
      sourceMapFilename: '[file].map'
    },
    module: {
      rules: [
        {
          test: /\.elm$/,
          exclude: [/elm-stuff/, /node_modules/],
          loader: 'elm-webpack-loader?pathToMake=node_modules/.bin/elm-make&warn=true&yes=true'
        }
      ]
    }
  };

  return merge(base,
    prod ? {
      plugins: [
        new webpack.optimize.UglifyJsPlugin({
          compress: { screw_ie8: true, warnings: false },
          mangle: true,
          output: { comments: false },
          sourceMap: true
        })
      ]
    } : {
      devtool: '#source-map',
      devServer: { historyApiFallback: true, port: 8000 }
    });
};
