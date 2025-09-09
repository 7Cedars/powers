const repo = args[0]
const path = args[1]
const author = args[2]

if (!repo || !path || !author) {
    throw Error("Missing required arguments: repo, path or author")
}

const url = `https://powers-protocol.vercel.app/api/github-commits?repo=${repo}&path=${path}&author=${author}` 

const resp = await Functions.makeHttpRequest({url}) 
if (resp.error) {
  throw Error("Request failed")
}

return Functions.encodeUint256(resp.data.data.commitCount)