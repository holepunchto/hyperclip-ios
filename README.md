
# Bare on iOS  
  
Hyperclip is an example of embedding Bare in an iOS application using <https://github.com/holepunchto/bare-kit>.  
  
You need [Hyperclip-desktop](https://github.com/supersuryaansh/hyperclip-desktop) to send clipboard content from Desktop to iOS.  
  
# Setup Instructions  
  

 1. Clone this repository
 2. Update the submodules `git submodule update --init --recursive `
 2. Run `npm install -g bare-dev && npm i `
 3. Configure build `bare-dev configure --debug --platform ios --arch arm64 --simulator`
 4. Build the App `bare-dev build --debug` 
 5. Run the application `bare-dev ios run --attach`
## License  
  
Apache-2.0