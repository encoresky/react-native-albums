import { NativeModules } from 'react-native';

type imageListOptions = {
    title: ?boolean,
    name: ?boolean,
    size: ?boolean,
    description: ?boolean,
    location: ?boolean,
    date: ?boolean,
    orientation: ?boolean,
    type: ?boolean,
    album: ?boolean,
    albumName: ?String,
    dimensions: ?boolean
};

type albumListOptions = {
    count: ?boolean,
    thumbnail: ?boolean,
    thumbnailDimensions: ?boolean
};

export default {
    getAlbumList(options: albumListOptions = {}) {
        return NativeModules.RNAlbumsModule.getAlbumList(options);
    },
    //get all album with image data
    getAllAlbumWithData(options: albumListOptions = {}) {
        return NativeModules.RNAlbumsModule.getAllAlbumWithData(options);
    },
    //get all photos with album name list(Only For IOS)
    getAllImageList(options: albumListOptions = {}){
        return NativeModules.RNAlbumsModule.getAllImageList(options);
    },
    //get images of perticuler album(Only For IOS)
    getImagesByAlbumName(options: albumListOptions = {}){
        return NativeModules.RNAlbumsModule.getImagesByAlbumName(options);
    }
};
