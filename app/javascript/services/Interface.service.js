import axios from "axios/index";
import * as _ from 'lodash';

class InterfaceService {
    constructor (params) {
        this.apiBasePath = params.apiBasePath;
        this.apiKey = params.apiKey;

        this.axiosInstance = axios.create({
            baseURL: this.apiBasePath,
            withCredentials: true
        });
        if(this.apiKey) {
            this.axiosInstance.headers = {
                Authorization: this.apiKey
            }
        }
        this.loading = false;
    }
    get(path, opts={}) {
        let defaultOptions= {
            parse: 'json_data'
        };
        _.mergeWith(defaultOptions, opts);
        let self = this;
        this.loading = true;
        return this.axiosInstance.get(path).then(function(res) {
            self.loading = false;
            if(opts.parse === 'json') {
                return res.data;
            }
            else if(opts.parse === 'json_data') {
                return res.data.data;
            }
            else {
                return res;
            }

        });
    }
}

export default InterfaceService;