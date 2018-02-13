import InterfaceService from './Interface.service.js'

class EmailServerInterfaceService extends InterfaceService {
    constructor () {
        super({
            apiBasePath: process.env.EMAIL_SERVER_BASE_PATH + "/api/v1",
            apiKey: process.env.EMAIL_SERVER_API_KEY
        });
    }
    getMessagesThread (id) {
        return this.get("/messages_threads/" + id);
    }

}
export default EmailServerInterfaceService;
