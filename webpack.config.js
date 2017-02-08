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
  entry: {
    //vendor: ['angular', 'konva'],
    demo: './src/demo/app.ts'
  },
  output: {
    path:  path.join(__dirname, 'build'),
    filename: '[name].bundle.js'
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
      template: 'src/demo/app.pug',
      // chunks: ['lib', 'demo'],
      // chunksSortMode: (chunk1,chunk2) => {
      //   var orders = ['vendor', 'demo']
      //   var order1 = orders.indexOf(chunk1.names[0])
      //   var order2 = orders.indexOf(chunk2.names[0])
      //   if (order1 > order2) {
      //     return 1
      //   } else if (order1 < order2) {
      //     return -1
      //   } else {
      //     return 0
      //   }
      // }
    }),
    // new LiveReloadPlugin({
    //   appendScriptTag: true
    // })
  ], // plugins
}