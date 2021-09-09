module.exports = {
    devtool: 'source-map',
    entry: "./src/simple_ts_solana.ts",
    mode: "development",
    output: {
        filename: "./simple_ts_solana.js",
        library: 'simple_ts_solana',
    },
    resolve: {
        extensions: ['.ts', '.js','.json'],
        aliasFields: ['browser', 'browser.esm']
    },
    module: {
        rules: [
            {
                test: /\.ts?$/,
                use: {
                    loader: 'ts-loader'
                }
            }
        ]
    }
}