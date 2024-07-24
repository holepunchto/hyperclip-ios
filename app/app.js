/* global Bare, BareKit */

Bare
  .on('suspend', () => console.log('suspended'))
  .on('resume', () => console.log('resumed'))
  .on('exit', () => console.log('exited'))

const Hyperswarm = require('hyperswarm')
const Hypercore = require('hypercore')
var fs = require('bare-fs');

// We need to store hypercore in /tmp/foldername
var dir = './tmp/hyperclip/';
// Check if the directory exists, delete and recreate if it already exists. Prevents issue while working with multiple hypercore
if (fs.existsSync(dir)) {
    // Remove the directory and its contents
    fs.rmSync(dir, { recursive: true, force: true });
}

// Create the directory
fs.mkdirSync(dir);

// Initialise Hyperswarm and Hypercore
// Replace HYPERCLIP_DESKTOP_KEY with the key you got from hyperclip desktop app.
// https://github.com/supersuryaansh/hyperclip-desktop
const swarm = new Hyperswarm()
const core = new Hypercore('./tmp/hyperclip/', "HYPERCLIP_DESKTOP_KEY")

// Create RPC
const rpc = new BareKit.RPC((req) => {
  //can establish two-way communication here later
})

async function main() {

    await core.ready()
    const foundPeers = core.findingPeers()
    swarm.join(core.discoveryKey)
    swarm.on('connection', conn => core.replicate(conn))
    // swarm.flush() will wait until *all* discoverable peers have been connected to
    // It might take a while, so don't await it
    // Instead, use core.findingPeers() to mark when the discovery process is completed
    swarm.flush().then(() => foundPeers())

    // This won't resolve until either
    //    a) the first peer is found
    // or b) no peers could be found
    await core.update()
    let position = core.length
    console.log(`Skipping ${core.length} earlier blocks...`)

    // Skip earlier block so that we have the latest clipboard data
    for await (const block of core.createReadStream({start: 0, live: true})) {
        // Send a RPC 'ping' signal to AppDelegate.m
        let req = rpc.request('ping')
        // Send data along with the ping. This contains clipboard content received from the desktop app.
        req.send(block)
        console.log(`Block ${position++}: ${block}`)
    }

}

main();
