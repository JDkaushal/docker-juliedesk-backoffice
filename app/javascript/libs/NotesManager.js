import $ from 'jquery';

class NotesManager {

    // Content Type
    static get TYPE_HTML() { return 'html' }
    static get TYPE_TEXT() { return 'text' }

    // Languages
    static get LANG_FR() { return 'fr'}
    static get LANG_EN() { return 'en' }
    static get SUPPORTED_LANGUAGES() { return [this.LANG_FR, this.LANG_EN]; }

    // Part content class name
    static get PART_CONTENT_CLASS_NAME()    { return 'content' }


    // Main Parts class names
    static get JULIEDESK_NOTES_CLASS_NAME() { return 'jd-description'}
    static get EMAIL_HISTORY_CLASS_NAME()   { return 'jd-email-history' }
    static get CUSTOMER_NOTES_CLASS_NAME()  { return 'jd-customer-notes' }

    // All Parts names
    static get MEETING_ROOMS_PART()         { return 'meetingRooms'}
    static get CALL_INSTRUCTIONS_PART()     { return 'callInstructions'}
    static get ADDRESS_DETAILS_PART()       { return 'addressDetails'}
    static get ORGANIZER_INFOS_PART()       { return 'organizerInfos' }
    static get CONTACT_INFOS_PART()         { return 'contactInfos'}
    static get SPECIFIC_NOTES_PART()        { return 'specificNotes' }
    static get EMAIL_HISTORY_PART()         { return 'emailHistory' }
    static get CUSTOMER_NOTES_PART()        { return 'customerNotes' }

    // Julie Desk Notes Part names
    static get JULIEDESK_NOTES_PARTS()      {
        return [
            this.MEETING_ROOMS_PART,
            this.CALL_INSTRUCTIONS_PART,
            this.ADDRESS_DETAILS_PART,
            this.ORGANIZER_INFOS_PART,
            this.CONTACT_INFOS_PART,
            this.SPECIFIC_NOTES_PART
        ];
    }




    // GENERAL TEMPLATE
    static get DEFAULT_HTML()            {
        return '<html>' +
            '<body>' +
            '<div>' +
            '<div class="' + NotesManager.JULIEDESK_NOTES_CLASS_NAME +'"></div>' +
            //'<div class="' + NotesManager.CUSTOMER_NOTES_CLASS_NAME +'"></div>' +
            '</div>' +
            '</body>' +
            '</html>';
    };
    static get PART_START_DELIMITER_TEMPLATE() { return  '<p class="startDelimiter">-{part-title}----------------</p>' };
    static get PART_END_DELIMITER_TEMPLATE()   { return  '<p class="endDelimiter">----------------------------------------</p>' };


    static get PARTS() {
        let parts = {};

        parts[this.MEETING_ROOMS_PART] = {
            'name': this.MEETING_ROOMS_PART,
            'className': 'jd-meeting-rooms',
            'title': {
                [NotesManager.LANG_FR]: 'Salles de réunion',
                [NotesManager.LANG_EN]: 'Meeting rooms',
            },
            'matchingTitles': ['Meeting rooms', 'Salles de réunion']
        };

        parts[this.CALL_INSTRUCTIONS_PART] = {
            'name': this.CALL_INSTRUCTIONS_PART,
            'className': 'jd-call-instructions',
            'title': {
                [NotesManager.LANG_FR]: 'Instructions-d\'appel',
                [NotesManager.LANG_EN]: 'Call-Instructions',
            },
            'matchingTitles': ['Instructions-d&#39;appel', 'Instructions-d\'appel', 'Call-Instructions']
        };

        parts[this.ADDRESS_DETAILS_PART] = {
            'name': this.ADDRESS_DETAILS_PART,
            'className': 'jd-address-details',
            'title': {
                [NotesManager.LANG_FR]: 'Complément-d\'Adresse',
                [NotesManager.LANG_EN]: 'Address-Details',
            },
            'matchingTitles': ['Complément-d\'Adresse', 'Complément-d#39;Adresse', 'Address-Details']
        };

        parts[this.ORGANIZER_INFOS_PART] = {
            'name': this.ORGANIZER_INFOS_PART,
            'className': 'jd-organizer-infos',
            'title': {
                [NotesManager.LANG_FR]: 'Informations-organisateur',
                [NotesManager.LANG_EN]: 'Organizer-infos'
            },
            'matchingTitles': ['Informations-organisateur', 'Organizer-Infos']
        };

        parts[this.CONTACT_INFOS_PART] = {
            'name': this.CONTACT_INFOS_PART,
            'className': 'jd-contact-infos',
            'title': {
                [NotesManager.LANG_FR]: 'Informations-de-contacts',
                [NotesManager.LANG_EN]: 'Contacts-Infos'
            },
            'matchingTitles': ['Informations-de-contacts', 'Contacts-Infos']
        };

        parts[this.SPECIFIC_NOTES_PART] = {
            'name': this.SPECIFIC_NOTES_PART,
            'className': 'jd-specific-notes',
            'title': {
                [NotesManager.LANG_FR]: 'Notes-additionnelles',
                [NotesManager.LANG_EN]: 'Additional-Infos'
            },
            'matchingTitles': ['Notes-additionnelles', 'Additional-Infos']
        };


        parts[this.EMAIL_HISTORY_PART] = {
            'name': this.EMAIL_HISTORY_PART,
            'className': 'jd-email-history',
            'title': null,
            'matchingTitles': ['Conversation', 'Thread']
        };

        parts[this.CUSTOMER_NOTES_PART] = {
            'name': this.CUSTOMER_NOTES_PART,
            'className': this.CUSTOMER_NOTES_CLASS_NAME,
            'title': null,
            'matchingTitles': ['Votre-contenu', 'Your-content']
        };

        return parts;
    }

    static fromEventDescription(content) {
        let noteManager = new NotesManager("", { contentType: NotesManager.TYPE_HTML });
        let customerContent = content.replace(/\[DESCRIPTION\](.*)\[\/DESCRIPTION\]/, '').replace(/-(.+)----\n[\s\S]+----\n/gm, '');
        noteManager.setCustomerNotes(customerContent);

        return noteManager;
    }

    static fromJulieDeskNotes(content, textContent) {
        let $html =  $(NotesManager.DEFAULT_HTML);
        $html.html(content);

        if($html.find('.' + NotesManager.JULIEDESK_NOTES_CLASS_NAME).size() == 0) {
            return new NotesManager(textContent, { contentType: NotesManager.TYPE_TEXT })
        }
        return new NotesManager(content, { contentType: NotesManager.TYPE_HTML });
    }


    constructor(content, options) {
        this.options = Object.assign({}, options || {});

        this.emailHistory = "";

        this.lang           = this.options.lang || 'fr';
        this.contentType    = this.options.contentType || NotesManager.TYPE_HTML;
        this.parts = {};

        // Set initial content (can be html or text)
        this.content = content || '';
        this.$html = $(NotesManager.DEFAULT_HTML);

        if(this.contentType == NotesManager.TYPE_HTML) {
            this.$html = $(content);
        }

        this.loadJulieDeskParts();
        this.updateNotes();
    }



    // Security
    // =================================================================================================================
    clean() {
        this.removeScripts();
    }

    removeScripts() {
        this.$html.find('script').remove();
    }



    changeLang(lang) {
        if(NotesManager.SUPPORTED_LANGUAGES.indexOf(this.lang) > -1)
            this.lang = lang;
    }



    // PARTS LOADING
    // =================================================================================================================
    loadJulieDeskParts() {
        for (let partName of NotesManager.JULIEDESK_NOTES_PARTS) {
            this.contentType == NotesManager.TYPE_HTML ?
                this.loadPart(partName, { mode: 'html' }) : this.loadPartAsText(partName);
        }
    }

    loadEmailHistory() {
        return this.loadPart(NotesManager.EMAIL_HISTORY_PART);
    }

    loadEmailHistoryAsText() {
        return this.loadPartAsText(NotesManager.EMAIL_HISTORY_PART);
    }

    loadCustomerNotes() {
        return this.loadPart(NotesManager.CUSTOMER_NOTES_PART, { getHTMLContent: true });
    }

    // TODO: REFACTOR
    loadCustomerNotesAsText() {
        let content = this.content;
        let contentBeginsAt = -1;
        let contentEndsAt;

        for(let title of NotesManager.PARTS[NotesManager.CUSTOMER_NOTES_PART].matchingTitles) {
            let start = content.indexOf(title);
            if(start > -1) {
                contentBeginsAt = start;
                break;
            }
        }

        // When no delimiter found (Your-content--- / Votre-contenu---)
        if(contentBeginsAt < 0)
            return this.loadCustomerNotesFallback(content);

        content = content.slice(contentBeginsAt);
        contentBeginsAt = content.indexOf("---\n") + 4;
        // Part not found
        if(contentBeginsAt < 0) return null;

        content = content.slice(contentBeginsAt);
        contentEndsAt = content.indexOf('\n---') - 1;
        content = content.slice(0, contentEndsAt);

        if(content)
            this.setCustomerNotes(content);

        return this.getCustomerNotes();
    }

    loadCustomerNotesFallback(content) {
        let customerNotes = content.replace(/-(.+)----\n[\s\S]+----\n/gm, '');
        this.setCustomerNotes(customerNotes);
        return this.getCustomerNotes();
    }

    loadPart(partName, options) {
        let mode = (options && options.mode) || 'text';

        let $part    = this.getElementByClassName(NotesManager.PARTS[partName].className);
        let $content = this.getElementByClassName(NotesManager.PART_CONTENT_CLASS_NAME, $part);
        this.setPart(partName, mode == 'html' ? $content.html() : $content.text());

        return this.getPart(partName);
    }

    loadPartAsText(partName) {
        let content = this.content;
        let contentBeginsAt = -1;
        let contentEndsAt;

        for(let title of NotesManager.PARTS[partName].matchingTitles) {
            let start = content.indexOf(title);
            if(start > -1) {
                contentBeginsAt = start;
                break;
            }
        }

        // Part not found
        if(contentBeginsAt < 0) return null;

        content = content.slice(contentBeginsAt);
        contentBeginsAt = content.indexOf("---\n") + 4;
        // Part not found
        if(contentBeginsAt < 0) return null;

        content = content.slice(contentBeginsAt);
        contentEndsAt = content.indexOf('\n---') - 1;
        content = content.slice(0, contentEndsAt);

        if(content)
            this.setPart(partName, content);

        return this.getPart(partName);
    }




    // Manage Parts  (get, set, remove, check)
    // =================================================================================================================
    getPart(partName){
        return this.parts[partName] || "";
    }

    setPart(partName, text) {
        if(text)
        // Replace starting and ending line breaks
            return this.parts[partName] = text.replace(/^\n+/, '').replace(/\n+$/, '');
        else {
            return this.removePart(partName);
        }
    }

    removePart(partName) {
        return delete this.parts[partName];
    }

    hasPart(partName) {
        return !!this.parts[partName];
    }




    // HTML Generation
    // =================================================================================================================
    updateNotes() {
        this.$html = $(NotesManager.DEFAULT_HTML);
        if(this.areJulieDeskNotesEmpty() === false)
            this.updateJulieDeskNotes();
        this.updateEmailHistory();
        this.updateCustomerNotes();
        this.clean();
        return this.$html.html();
    }

    updateJulieDeskNotes() {
        let $notesNode  = this.getJulieDeskNotesNode();

        // Julie Desk Notes
        if($notesNode.size() == 0)
            $notesNode = this.$html.append('<div class="' + NotesManager.JULIEDESK_NOTES_CLASS_NAME + '"></div>');
        else
            $notesNode.html('');

        $notesNode.append("<p>[DESCRIPTION]</p>");
        for(let partName of NotesManager.JULIEDESK_NOTES_PARTS) {
            let partConfig = NotesManager.PARTS[partName];
            if(this.hasPart(partName))
                $notesNode.append(this.generateHTMLPart(partConfig)).append('<br/>');
        }
        $notesNode.append("<p>[/DESCRIPTION]</p>");

        return this.$html;
    }

    updateCustomerNotes() {
        let $customerNotesNode = this.getCustomerNotesNode();
        $customerNotesNode.remove();
        this.$html.append(this.generateCustomerNotesHTML());
        return this.$html;
    }

    updateEmailHistory() {
        this.getEmailHistoryNode().remove();
        if(!this.getEmailHistory())
            return this.$html;

        this.$html.append(
            "<p>- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -</p>",
            this.generateEmailHistoryHTML(),
            "<p>- - - - - - - - - - - - - - - - - - - - - - - - - - - - - -</p>"
        );
        return this.$html;
    }

    updateNotesFromOtherNotes(notes) {
        this.changeLang(notes.lang);
        for(const partName of NotesManager.JULIEDESK_NOTES_PARTS){
            this.setPart(partName, notes.getPart(partName))
        }
        return this.updateNotes();
    }

    generateHTMLPart(partConfig) {
        let $partHtml       = $('<div class="'+ partConfig.className +'"></div>');
        let $content        = $('<p class="content">'+ this.getPart(partConfig.name).replace(/\n/, "<br />") + '</p>');

        if(partConfig.title) {
            let $startDelimiter = $(this.generateStartDelimiter(partConfig.name));
            let $endDelimiter   = $(this.generateEndDelimiter());
            return $partHtml.append([$startDelimiter, $content, $endDelimiter]);
        }
        else
            return $partHtml.append($content);
    }

    generateCustomerNotesHTML(){
        return this.generateHTMLPart(NotesManager.PARTS[NotesManager.CUSTOMER_NOTES_PART]);
    }

    generateEmailHistoryHTML() {
        return this.generateHTMLPart(NotesManager.PARTS[NotesManager.EMAIL_HISTORY_PART]);
    }


    generateStartDelimiter(partName) {
        const part = NotesManager.PARTS[partName];
        if(!part)
            return "";

        const title = part.title[this.lang] || partName;
        return NotesManager.PART_START_DELIMITER_TEMPLATE.replace(/\{part-title\}/, title);
    }


    generateEndDelimiter() {
        return NotesManager.PART_END_DELIMITER_TEMPLATE;
    }



    // HTML NODES (as jQuery elements)
    // =================================================================================================================
    getFullNotesNode() {
        return this.$html;
    }

    getJulieDeskNotesNode() {
        return this.getElementByClassName(NotesManager.JULIEDESK_NOTES_CLASS_NAME);
    }

    getEmailHistoryNode() {
        return this.getElementByClassName(NotesManager.EMAIL_HISTORY_CLASS_NAME);
    }

    getCustomerNotesNode() {
        return this.getElementByClassName(NotesManager.CUSTOMER_NOTES_CLASS_NAME);
    }



    // HTML OUTPUT (as text)
    // =================================================================================================================
    getFullNotesOutputHTML(){
        return this.getFullNotesNode().wrap('<p>').parent().html();
    }

    getJulieDeskNotesHTML() {
        return this.getJulieDeskNotesNode().wrap('<p>').parent().html();
    }

    getElementByClassName(className, rootElement) {
        const $rootElement = rootElement || this.$html;
        const selector = '.' + className;
        let $element = $rootElement.find(selector);
        return $element.size() == 0 ? $rootElement.find('*[class*="'+ className +'"]') : $element
    }




    // Parts getters and setters
    // =================================================================================================================

    // Meeting Rooms
    getMeetingRoomsInstructions() {
        return this.getPart(NotesManager.MEETING_ROOMS_PART);
    }

    setMeetingRoomsInstructions(text) {
        return this.setPart(NotesManager.MEETING_ROOMS_PART, text);
    }


    // Call Instructions
    getCallInstructions() {
        return this.getPart(NotesManager.CALL_INSTRUCTIONS_PART);
    }

    setCallInstructions(text) {
        return this.setPart(NotesManager.CALL_INSTRUCTIONS_PART, text);
    }


    // Address Details
    getAddressDetails() {
        return this.getPart(NotesManager.ADDRESS_DETAILS_PART);
    }

    setAddressDetails(text) {
        return this.setPart(NotesManager.ADDRESS_DETAILS_PART, text);
    }


    // Organizer Infos
    getOrganizerInfos() {
        return this.getPart(NotesManager.ORGANIZER_INFOS_PART);
    }

    setOrganizerInfos(text) {
        return this.setPart(NotesManager.ORGANIZER_INFOS_PART, text);
    }


    // Contact Infos
    getContactInfos() {
        return this.getPart(NotesManager.CONTACT_INFOS_PART);
    }

    setContactInfos(text) {
        return this.setPart(NotesManager.CONTACT_INFOS_PART, text);
    }


    // Specific Notes
    getSpecificNotes() {
        return this.getPart(NotesManager.SPECIFIC_NOTES_PART);
    }

    setSpecificNotes(text) {
        return this.setPart(NotesManager.SPECIFIC_NOTES_PART, text);
    }

    getEmailHistory() {
        return this.getPart(NotesManager.EMAIL_HISTORY_PART);
    }

    setEmailHistory(text) {
        return this.setPart(NotesManager.EMAIL_HISTORY_PART, text);
    }

    getCustomerNotes() {
        return this.getPart(NotesManager.CUSTOMER_NOTES_PART);
    }

    setCustomerNotes(text) {
        return this.setPart(NotesManager.CUSTOMER_NOTES_PART, text);
    }

    areJulieDeskNotesEmpty() {
        for(const partName of NotesManager.JULIEDESK_NOTES_PARTS) {
            if(this.getPart(partName))
                return false;
        }
        return true;
    }

}

export default NotesManager;