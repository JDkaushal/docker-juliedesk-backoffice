import axios from "axios/index";
import * as _ from 'lodash';

class InterfaceService {
    constructor (params) {
        this.apiBasePath = params.apiBasePath;
        this.apiKey = params.apiKey;

        if(this.apiKey) {
            this.axiosInstance = axios.create({
                baseURL: this.apiBasePath,
                headers: {
                    Authorization: this.apiKey
                }
            })
        }
        else {
            this.axiosInstance = axios.create({
                baseURL: this.apiBasePath,
                withCredentials: true
            });
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
            if(defaultOptions.parse === 'json') {
                return res.data;
            }
            else if(defaultOptions.parse === 'json_data') {
                return res.data.data;
            }
            else if(defaultOptions.parse === 'json_results') {
                return res.data.results;
            }
            else {
                return res;
            }

        });
    }
}

export default InterfaceService;