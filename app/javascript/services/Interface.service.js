import axios from "axios/index";

class InterfaceService {
    constructor (params) {
        this.apiBasePath = params.apiBasePath;
        this.apiKey = params.apiKey;

        this.axiosInstance = axios.create({
            baseURL: this.apiBasePath,
            headers: {
                Authorization: this.apiKey
            }
        });
    }
    get(path) {
        return this.axiosInstance.get(path).then(function(res) {
            return res.data.data;
        });
    }
}

export default InterfaceService;