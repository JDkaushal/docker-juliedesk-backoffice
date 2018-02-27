import InterfaceService from './Interface.service.js'

class ConscienceInterfaceService extends InterfaceService {
    constructor () {
        super({
            apiBasePath: process.env.CONSCIENCE_BASE_PATH + "/api/v1",
            apiKey: process.env.CONSCIENCE_API_KEY
        });
    }

    getStatsAnonymisedMessagesThreads() {
        return this.get("/anonymisation/threads/stats");
    }

    listAnonymisedMessagesThreads() {
        return this.get("/anonymisation/threads")
    }

    getMessagesThread(threadId) {
        return this.get(`/anonymisation/threads/${threadId}`)
    }
}

export default ConscienceInterfaceService;