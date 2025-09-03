package mx.d3c.dev.ine;

import android.os.Parcel;
import android.os.Parcelable;
import org.json.JSONException;
import org.json.JSONObject;

/**
 * Modelo de datos para el resultado del procesamiento de credenciales INE
 * Implementa Parcelable para transferencia entre procesos Android
 */
public class CredentialResult implements Parcelable {
    private String nombre;
    private String domicilio;
    private String claveElector;
    private String curp;
    private String fechaNacimiento;
    private String sexo;
    private String anoRegistro;
    private String seccion;
    private String vigencia;
    private String tipo;
    private String lado;
    private String estado;
    private String municipio;
    private String localidad;
    private String photoPath;
    private String signaturePath;
    private String qrContent;
    private String qrImagePath;
    private String barcodeContent;
    private String barcodeImagePath;
    private String mrzContent;
    private String mrzImagePath;
    private String mrzDocumentNumber;
    private String mrzNationality;
    private String mrzBirthDate;
    private String mrzExpiryDate;
    private String mrzSex;
    private String signatureHuellaImagePath;
    private boolean isAcceptable;
    private long processingTimeMs;
    private String errorMessage;

    public CredentialResult() {
        // Constructor vacío
    }

    protected CredentialResult(Parcel in) {
        nombre = in.readString();
        domicilio = in.readString();
        claveElector = in.readString();
        curp = in.readString();
        fechaNacimiento = in.readString();
        sexo = in.readString();
        anoRegistro = in.readString();
        seccion = in.readString();
        vigencia = in.readString();
        tipo = in.readString();
        lado = in.readString();
        estado = in.readString();
        municipio = in.readString();
        localidad = in.readString();
        photoPath = in.readString();
        signaturePath = in.readString();
        qrContent = in.readString();
        qrImagePath = in.readString();
        barcodeContent = in.readString();
        barcodeImagePath = in.readString();
        mrzContent = in.readString();
        mrzImagePath = in.readString();
        mrzDocumentNumber = in.readString();
        mrzNationality = in.readString();
        mrzBirthDate = in.readString();
        mrzExpiryDate = in.readString();
        mrzSex = in.readString();
        signatureHuellaImagePath = in.readString();
        isAcceptable = in.readByte() != 0;
        processingTimeMs = in.readLong();
        errorMessage = in.readString();
    }

    @Override
    public void writeToParcel(Parcel dest, int flags) {
        dest.writeString(nombre);
        dest.writeString(domicilio);
        dest.writeString(claveElector);
        dest.writeString(curp);
        dest.writeString(fechaNacimiento);
        dest.writeString(sexo);
        dest.writeString(anoRegistro);
        dest.writeString(seccion);
        dest.writeString(vigencia);
        dest.writeString(tipo);
        dest.writeString(lado);
        dest.writeString(estado);
        dest.writeString(municipio);
        dest.writeString(localidad);
        dest.writeString(photoPath);
        dest.writeString(signaturePath);
        dest.writeString(qrContent);
        dest.writeString(qrImagePath);
        dest.writeString(barcodeContent);
        dest.writeString(barcodeImagePath);
        dest.writeString(mrzContent);
        dest.writeString(mrzImagePath);
        dest.writeString(mrzDocumentNumber);
        dest.writeString(mrzNationality);
        dest.writeString(mrzBirthDate);
        dest.writeString(mrzExpiryDate);
        dest.writeString(mrzSex);
        dest.writeString(signatureHuellaImagePath);
        dest.writeByte((byte) (isAcceptable ? 1 : 0));
        dest.writeLong(processingTimeMs);
        dest.writeString(errorMessage);
    }

    @Override
    public int describeContents() {
        return 0;
    }

    public static final Creator<CredentialResult> CREATOR = new Creator<CredentialResult>() {
        @Override
        public CredentialResult createFromParcel(Parcel in) {
            return new CredentialResult(in);
        }

        @Override
        public CredentialResult[] newArray(int size) {
            return new CredentialResult[size];
        }
    };

    /**
     * Convierte el resultado a JSON
     */
    public String toJson() {
        try {
            JSONObject json = new JSONObject();
            json.put("nombre", nombre != null ? nombre : "");
            json.put("domicilio", domicilio != null ? domicilio : "");
            json.put("claveElector", claveElector != null ? claveElector : "");
            json.put("curp", curp != null ? curp : "");
            json.put("fechaNacimiento", fechaNacimiento != null ? fechaNacimiento : "");
            json.put("sexo", sexo != null ? sexo : "");
            json.put("anoRegistro", anoRegistro != null ? anoRegistro : "");
            json.put("seccion", seccion != null ? seccion : "");
            json.put("vigencia", vigencia != null ? vigencia : "");
            json.put("tipo", tipo != null ? tipo : "");
            json.put("lado", lado != null ? lado : "");
            json.put("estado", estado != null ? estado : "");
            json.put("municipio", municipio != null ? municipio : "");
            json.put("localidad", localidad != null ? localidad : "");
            json.put("photoPath", photoPath != null ? photoPath : "");
            json.put("signaturePath", signaturePath != null ? signaturePath : "");
            json.put("qrContent", qrContent != null ? qrContent : "");
            json.put("qrImagePath", qrImagePath != null ? qrImagePath : "");
            json.put("barcodeContent", barcodeContent != null ? barcodeContent : "");
            json.put("barcodeImagePath", barcodeImagePath != null ? barcodeImagePath : "");
            json.put("mrzContent", mrzContent != null ? mrzContent : "");
            json.put("mrzImagePath", mrzImagePath != null ? mrzImagePath : "");
            json.put("mrzDocumentNumber", mrzDocumentNumber != null ? mrzDocumentNumber : "");
            json.put("mrzNationality", mrzNationality != null ? mrzNationality : "");
            json.put("mrzBirthDate", mrzBirthDate != null ? mrzBirthDate : "");
            json.put("mrzExpiryDate", mrzExpiryDate != null ? mrzExpiryDate : "");
            json.put("mrzSex", mrzSex != null ? mrzSex : "");
            json.put("signatureHuellaImagePath", signatureHuellaImagePath != null ? signatureHuellaImagePath : "");
            json.put("isAcceptable", isAcceptable);
            json.put("processingTimeMs", processingTimeMs);
            json.put("errorMessage", errorMessage != null ? errorMessage : "");
            return json.toString();
        } catch (JSONException e) {
            return "{}";
        }
    }

    /**
     * Crea un CredentialResult desde JSON
     */
    public static CredentialResult fromJson(String jsonString) {
        try {
            JSONObject json = new JSONObject(jsonString);
            CredentialResult result = new CredentialResult();
            
            result.nombre = json.optString("nombre", "");
            result.domicilio = json.optString("domicilio", "");
            result.claveElector = json.optString("claveElector", "");
            result.curp = json.optString("curp", "");
            result.fechaNacimiento = json.optString("fechaNacimiento", "");
            result.sexo = json.optString("sexo", "");
            result.anoRegistro = json.optString("anoRegistro", "");
            result.seccion = json.optString("seccion", "");
            result.vigencia = json.optString("vigencia", "");
            result.tipo = json.optString("tipo", "");
            result.lado = json.optString("lado", "");
            result.estado = json.optString("estado", "");
            result.municipio = json.optString("municipio", "");
            result.localidad = json.optString("localidad", "");
            result.photoPath = json.optString("photoPath", "");
            result.signaturePath = json.optString("signaturePath", "");
            result.qrContent = json.optString("qrContent", "");
            result.qrImagePath = json.optString("qrImagePath", "");
            result.barcodeContent = json.optString("barcodeContent", "");
            result.barcodeImagePath = json.optString("barcodeImagePath", "");
            result.mrzContent = json.optString("mrzContent", "");
            result.mrzImagePath = json.optString("mrzImagePath", "");
            result.mrzDocumentNumber = json.optString("mrzDocumentNumber", "");
            result.mrzNationality = json.optString("mrzNationality", "");
            result.mrzBirthDate = json.optString("mrzBirthDate", "");
            result.mrzExpiryDate = json.optString("mrzExpiryDate", "");
            result.mrzSex = json.optString("mrzSex", "");
            result.signatureHuellaImagePath = json.optString("signatureHuellaImagePath", "");
            result.isAcceptable = json.optBoolean("isAcceptable", false);
            result.processingTimeMs = json.optLong("processingTimeMs", 0);
            result.errorMessage = json.optString("errorMessage", "");
            
            return result;
        } catch (JSONException e) {
            return new CredentialResult();
        }
    }

    // Getters y Setters
    public String getNombre() { return nombre; }
    public void setNombre(String nombre) { this.nombre = nombre; }
    
    public String getDomicilio() { return domicilio; }
    public void setDomicilio(String domicilio) { this.domicilio = domicilio; }
    
    public String getClaveElector() { return claveElector; }
    public void setClaveElector(String claveElector) { this.claveElector = claveElector; }
    
    public String getCurp() { return curp; }
    public void setCurp(String curp) { this.curp = curp; }
    
    public String getFechaNacimiento() { return fechaNacimiento; }
    public void setFechaNacimiento(String fechaNacimiento) { this.fechaNacimiento = fechaNacimiento; }
    
    public String getSexo() { return sexo; }
    public void setSexo(String sexo) { this.sexo = sexo; }
    
    public String getAnoRegistro() { return anoRegistro; }
    public void setAnoRegistro(String anoRegistro) { this.anoRegistro = anoRegistro; }
    
    public String getSeccion() { return seccion; }
    public void setSeccion(String seccion) { this.seccion = seccion; }
    
    public String getVigencia() { return vigencia; }
    public void setVigencia(String vigencia) { this.vigencia = vigencia; }
    
    public String getTipo() { return tipo; }
    public void setTipo(String tipo) { this.tipo = tipo; }
    
    public String getLado() { return lado; }
    public void setLado(String lado) { this.lado = lado; }
    
    public String getEstado() { return estado; }
    public void setEstado(String estado) { this.estado = estado; }
    
    public String getMunicipio() { return municipio; }
    public void setMunicipio(String municipio) { this.municipio = municipio; }
    
    public String getLocalidad() { return localidad; }
    public void setLocalidad(String localidad) { this.localidad = localidad; }
    
    public boolean isAcceptable() { return isAcceptable; }
    public void setAcceptable(boolean acceptable) { isAcceptable = acceptable; }
    
    public long getProcessingTimeMs() { return processingTimeMs; }
    public void setProcessingTimeMs(long processingTimeMs) { this.processingTimeMs = processingTimeMs; }
    
    public String getErrorMessage() { return errorMessage; }
    public void setErrorMessage(String errorMessage) { this.errorMessage = errorMessage; }

    // Getters y setters para campos adicionales
    public String getPhotoPath() { return photoPath; }
    public void setPhotoPath(String photoPath) { this.photoPath = photoPath; }
    
    public String getSignaturePath() { return signaturePath; }
    public void setSignaturePath(String signaturePath) { this.signaturePath = signaturePath; }
    
    public String getQrContent() { return qrContent; }
    public void setQrContent(String qrContent) { this.qrContent = qrContent; }
    
    public String getQrImagePath() { return qrImagePath; }
    public void setQrImagePath(String qrImagePath) { this.qrImagePath = qrImagePath; }
    
    public String getBarcodeContent() { return barcodeContent; }
    public void setBarcodeContent(String barcodeContent) { this.barcodeContent = barcodeContent; }
    
    public String getBarcodeImagePath() { return barcodeImagePath; }
    public void setBarcodeImagePath(String barcodeImagePath) { this.barcodeImagePath = barcodeImagePath; }
    
    public String getMrzContent() { return mrzContent; }
    public void setMrzContent(String mrzContent) { this.mrzContent = mrzContent; }
    
    public String getMrzImagePath() { return mrzImagePath; }
    public void setMrzImagePath(String mrzImagePath) { this.mrzImagePath = mrzImagePath; }
    
    public String getMrzDocumentNumber() { return mrzDocumentNumber; }
    public void setMrzDocumentNumber(String mrzDocumentNumber) { this.mrzDocumentNumber = mrzDocumentNumber; }
    
    public String getMrzNationality() { return mrzNationality; }
    public void setMrzNationality(String mrzNationality) { this.mrzNationality = mrzNationality; }
    
    public String getMrzBirthDate() { return mrzBirthDate; }
    public void setMrzBirthDate(String mrzBirthDate) { this.mrzBirthDate = mrzBirthDate; }
    
    public String getMrzExpiryDate() { return mrzExpiryDate; }
    public void setMrzExpiryDate(String mrzExpiryDate) { this.mrzExpiryDate = mrzExpiryDate; }
    
    public String getMrzSex() { return mrzSex; }
    public void setMrzSex(String mrzSex) { this.mrzSex = mrzSex; }
    
    public String getSignatureHuellaImagePath() { return signatureHuellaImagePath; }
    public void setSignatureHuellaImagePath(String signatureHuellaImagePath) { this.signatureHuellaImagePath = signatureHuellaImagePath; }
}