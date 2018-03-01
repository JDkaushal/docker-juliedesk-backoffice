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

        let options = this.optionsWithDefaults(opts)
        let self = this;
        this.loading = true;

        return this.axiosInstance.get(path).then(function(response) {
            self.loading = false;
            return self.parseResponse(response, options)
        });
    }

    post(path, data={}, opts={}) {
        let options = this.optionsWithDefaults(opts)
        let self = this;
        this.loading = true;

        return this.axiosInstance.post(path, data).then(function(response) {
            self.loading = false;
            return self.parseResponse(response, options)
        });
    }

    optionsWithDefaults(opts={}) {
        let defaultOptions= {
            parse: 'json_data'
        };
        return _.mergeWith(defaultOptions, opts);
    }

    parseResponse(response, options) {
        if(options.parse === 'json') {
            return response.data;
        }
        else if(options.parse === 'json_data') {
            return response.data.data;
        }
        else if(options.parse === 'json_results') {
            return response.data.results;
        }
        else {
            return response;
        }
    }
}

export default InterfaceService;