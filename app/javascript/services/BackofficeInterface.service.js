import InterfaceService from './Interface.service.js'

class BackofficeInterfaceService extends InterfaceService {
    constructor () {
        super({
            apiBasePath: "/"
        });
    }
    listMessagesThreads () {
        return this.get("/messages_threads.json", {
            parse: 'json'
        });
    }

}
export default BackofficeInterfaceService;
