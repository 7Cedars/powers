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
    }
};

export default nextConfig;