import InterfaceService from './Interface.service'

class TrackingInterfaceService extends InterfaceService {
    constructor () {
        super({
            apiBasePath: process.env.BACKOFFICE_ANALYTICS_BASE_PATH + "/api/v1",
            apiKey: process.env.JD_BACKOFFICE_API_KEY
        });
    }

    track(event, data={}) {
        return this.post("/track", {
                name: event,
                date: (new Date()).toISOString(),
                properties: data,
                distinct_id: data.distinct_id
            })
    }
}

export default TrackingInterfaceService;