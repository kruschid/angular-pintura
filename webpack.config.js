var path = require('path'),
    HtmlWebpackPlugin = require('html-webpack-plugin');
    // LiveReloadPlugin = require('webpack-livereload-plugin');

module.exports = {
  devtool: 'inline-source-map',
  devServer: {
    historyApiFallback: true,
    hot: true,
    inline: true,
    contentBase: './build',
    port: 8080,
  },
  entry: './demo/app.ts',
  output: {
    path:  path.join(__dirname, 'build'),
    filename: 'bundle.js' 
  },
  resolve: {
    extensions: ['.ts','.js']
  },
  module: {
    loaders: [
      { test: /\.sass$/, loaders:['style-loader', 'css-loader', 'sass-loader']},
      { test: /\.ts$/, loader: "awesome-typescript-loader" },
      { test: /\.pug$/, loader: "pug-loader" },
      { 
        test: /\.(ttf|eot|woff2?|svg)$/, 
        loader: 'url-loader',
        options: {
          limit: 100000
        }
      }
    ]
  }, // module
  plugins: [
    new HtmlWebpackPlugin({
      filename: 'index.html',
      template: 'demo/app.pug'
    }),
    // new LiveReloadPlugin({
    //   appendScriptTag: true
    // })
  ], // plugins
  // externals: {
  //   'angular': 'angular',
  // }
}