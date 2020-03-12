package im.shimo.react.albums;

import android.database.Cursor;
import android.net.Uri;
import android.provider.MediaStore;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableMap;
import com.google.gson.Gson;
import com.google.gson.GsonBuilder;
import com.google.gson.JsonArray;

import java.util.ArrayList;

public class RNAlbumsModule extends ReactContextBaseJavaModule {

    private static String TAG="RNAlbumsModule";

    public RNAlbumsModule(ReactApplicationContext reactContext) {
        super(reactContext);
    }

    @Override
    public String getName() {
        return "RNAlbumsModule";
    }


    @ReactMethod
    public void getImageList(ReadableMap options, Promise promise) {

        ArrayList<MediaData> albumList = new ArrayList<>();
        final String[] projection = {
                MediaStore.Files.FileColumns._ID,
                MediaStore.Files.FileColumns.DATA,
                MediaStore.Files.FileColumns.DATE_ADDED,
                MediaStore.Files.FileColumns.MEDIA_TYPE,
                MediaStore.Files.FileColumns.MIME_TYPE,
                MediaStore.Files.FileColumns.TITLE,
                MediaStore.Images.Media.BUCKET_DISPLAY_NAME,
                MediaStore.Video.Media.BUCKET_DISPLAY_NAME
        };

        // Return only video and image metadata.
        String selection = MediaStore.Files.FileColumns.MEDIA_TYPE + "="
                + MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE
                + " OR "
                + MediaStore.Files.FileColumns.MEDIA_TYPE + "="
                + MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO;

        Uri queryUri = MediaStore.Files.getContentUri("external");

        final String orderBy = MediaStore.Images.Media.DATE_TAKEN;
        int tempPosition = 0;
        Cursor cursor;
        int columnIndexDataUri, columnIndexDataType, columnIndexImageFolderName, columnIndexVideoFolderName;
        String tempAbsImagePath = null, tempMediaType = null, tempMediaFolder = null;
        boolean isFolder = false;

        albumList.clear();
        cursor = getReactApplicationContext().getContentResolver().query(queryUri, projection, selection, null, orderBy + " DESC");
        columnIndexDataUri = cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.DATA);
        columnIndexDataType = cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.MEDIA_TYPE);
        columnIndexImageFolderName = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.BUCKET_DISPLAY_NAME);
        columnIndexVideoFolderName = cursor.getColumnIndexOrThrow(MediaStore.Video.Media.BUCKET_DISPLAY_NAME);
        while (cursor.moveToNext()) {
            tempAbsImagePath = cursor.getString(columnIndexDataUri);
            tempMediaType = cursor.getString(columnIndexDataType);

            if (tempMediaType.equalsIgnoreCase("1")) {
                tempMediaFolder = cursor.getString(columnIndexImageFolderName);
                tempMediaType = "ALAssetTypePhoto";

            } else if (tempMediaType.equalsIgnoreCase("3")) {
                tempMediaFolder = cursor.getString(columnIndexVideoFolderName);
                tempMediaType = "ALAssetTypeVideo";
            }

            albumList.add(new MediaData(tempAbsImagePath, tempMediaType));

        }
        Gson gson = new GsonBuilder().create();
        JsonArray myCustomArray = gson.toJsonTree(albumList).getAsJsonArray();

        promise.resolve(myCustomArray.toString());
    }

    @ReactMethod
    public void getAlbumList(ReadableMap options, Promise promise) {


        ArrayList<ImageModel> albumList = new ArrayList<>();
        ArrayList<MediaData> allMediaList = new ArrayList<>();
        final String[] projection = {
                MediaStore.Files.FileColumns._ID,
                MediaStore.Files.FileColumns.DATA,
                MediaStore.Files.FileColumns.DATE_ADDED,
                MediaStore.Files.FileColumns.MEDIA_TYPE,
                MediaStore.Files.FileColumns.MIME_TYPE,
                MediaStore.Files.FileColumns.TITLE,
                MediaStore.Images.Media.BUCKET_DISPLAY_NAME,
                MediaStore.Video.Media.BUCKET_DISPLAY_NAME
        };

        // Return only video and image metadata.
        String selection = MediaStore.Files.FileColumns.MEDIA_TYPE + "="
                + MediaStore.Files.FileColumns.MEDIA_TYPE_IMAGE
                + " OR "
                + MediaStore.Files.FileColumns.MEDIA_TYPE + "="
                + MediaStore.Files.FileColumns.MEDIA_TYPE_VIDEO;

        Uri queryUri = MediaStore.Files.getContentUri("external");

        final String orderBy = MediaStore.Images.Media.DATE_TAKEN;
        int tempPosition = 0;
        Cursor cursor;
        int columnIndexDataUri, columnIndexDataType, columnIndexImageFolderName, columnIndexVideoFolderName;
        String tempAbsImagePath = null, tempMediaType = null, tempMediaFolder = null;
        boolean isFolder = false;

        albumList.clear();
        allMediaList.clear();
        cursor = getReactApplicationContext().getContentResolver().query(queryUri, projection, selection, null, orderBy + " DESC");
        columnIndexDataUri = cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.DATA);
        columnIndexDataType = cursor.getColumnIndexOrThrow(MediaStore.Files.FileColumns.MEDIA_TYPE);
        columnIndexImageFolderName = cursor.getColumnIndexOrThrow(MediaStore.Images.Media.BUCKET_DISPLAY_NAME);
        columnIndexVideoFolderName = cursor.getColumnIndexOrThrow(MediaStore.Video.Media.BUCKET_DISPLAY_NAME);
        while (cursor.moveToNext()) {
            tempAbsImagePath = cursor.getString(columnIndexDataUri);
            tempMediaType = cursor.getString(columnIndexDataType);

            if (tempMediaType.equalsIgnoreCase("1")) {
                tempMediaFolder = cursor.getString(columnIndexImageFolderName);
                tempMediaType = "ALAssetTypePhoto";

            } else if (tempMediaType.equalsIgnoreCase("3")) {
                tempMediaFolder = cursor.getString(columnIndexVideoFolderName);
                tempMediaType = "ALAssetTypeVideo";
            }

            if (albumList.size() == 0)
                isFolder = false;
            for (int i = 0; i < albumList.size(); i++) {
                if (albumList.get(i).getStr_folder() != null && albumList.get(i).getStr_folder().equals(cursor.getString(columnIndexImageFolderName))) {
                    isFolder = true;
                    tempPosition = i;
                    break;
                } else {
                    isFolder = false;
                }
            }
            ArrayList<MediaData> al_path;
            if (isFolder) {
                al_path = new ArrayList<>();
                al_path.addAll(albumList.get(tempPosition).getAl_imagepath());
                al_path.add(new MediaData(tempAbsImagePath, tempMediaType));
                albumList.get(tempPosition).setAlbumMedia(al_path);
            } else {
                al_path = new ArrayList<>();
                al_path.add(new MediaData(tempAbsImagePath, tempMediaType));
                ImageModel obj_model = new ImageModel();
                obj_model.setAlbum(cursor.getString(columnIndexImageFolderName));
                obj_model.setAlbumMedia(al_path);
                albumList.add(obj_model);
            }
            allMediaList.add(new MediaData(tempAbsImagePath, tempMediaType));
        }
        ImageModel data = new ImageModel();
        data.setAlbum("All Photos");
        data.setAlbumMedia(allMediaList);
        albumList.add(data);

        Gson gson = new GsonBuilder().create();
        JsonArray myCustomArray = gson.toJsonTree(albumList).getAsJsonArray();

//        Log.e(TAG, "getImages: albumList >> " + albumList);
//        Log.e(TAG, "getImages: myCustomArray >> " + myCustomArray);
        promise.resolve(myCustomArray.toString());
    }

    public class ImageModel {
        String album;
        ArrayList<MediaData> album_media;
        String type;

        public String getStr_folder() {
            return album;
        }

        public void setAlbum(String album) {
            this.album = album;
        }

        public ArrayList<MediaData> getAl_imagepath() {
            return album_media;
        }

        public void setAlbumMedia(ArrayList<MediaData> album_media) {
            this.album_media = album_media;
        }

        @Override
        public String toString() {
            return "{" +
                    "album='" + album + '\'' +
                    ", album_media=" + album_media +
                    '}';
        }
    }

    

    public class MediaData {
        String uri;
        String type;

        public MediaData(String uri, String type) {
            this.uri= "file://" + uri;
           this. type=type;

        }

        public String getUri() {
            return uri;
        }

        public void setUri(String uri) {
            this.uri =  uri;
        }

        public String getType() {
            return type;
        }

        public void setType(String type) {
            this.type = type;
        }

        @Override
        public String toString() {
            return "{uri='" +  uri + '\'' +
                    ", type='" + type + '\'' +
                    '}';
        }
    }


    private boolean shouldSetField(ReadableMap options, String name) {
        return options.hasKey(name) && options.getBoolean(name);
    }

    private void setWritableMap(WritableMap map, String key, String value) {
        if (value == null) {
            map.putNull(key);
        } else {
            map.putString(key, value);
        }
    }

    private void setColumn(String name, String columnName, ArrayList<String> projection, ArrayList<ReadableMap> columns) {
        projection.add(columnName);
        WritableMap column = Arguments.createMap();
        column.putString("name", name);
        column.putString("columnName", columnName);
        columns.add(column);
    }
}
