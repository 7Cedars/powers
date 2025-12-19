/** @type {import('next').NextConfig} */
const nextConfig = { 
    images: {
        remotePatterns: [
            {
                protocol: 'https',
                hostname: 'aqua-famous-sailfish-288.mypinata.cloud',
                pathname: '/ipfs/**',
            }
        ],
    },
    
    webpack: (config, { isServer }) => {
        // Exclude test files and test dependencies from bundle
        config.module.rules.push({
            test: /node_modules\/(thread-stream|pino).*\/(test|bench).*\.(js|mjs|ts|tsx)$/,
            type: 'javascript/auto',
            use: 'null-loader'
        });
        
        // Ignore LICENSE files and other non-JS files in node_modules
        config.module.rules.push({
            test: /node_modules\/.*\/(LICENSE|README\.md|\.zip|\.sh|\.yml)$/,
            type: 'javascript/auto',
            use: 'null-loader'
        });
        
        // Add resolve fallbacks for node modules
        config.resolve.fallback = {
            ...config.resolve.fallback,
            fs: false,
            net: false,
            tls: false,
        };
        
        return config;
    }
};

export default nextConfig;
