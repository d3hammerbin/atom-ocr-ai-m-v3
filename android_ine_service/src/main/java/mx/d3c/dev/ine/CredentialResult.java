package mx.d3c.dev.ine;

import android.os.Parcel;
import android.os.Parcelable;
import org.json.JSONException;
import org.json.JSONObject;

/**
 * Modelo de datos completo para el resultado del procesamiento de credenciales INE
 * Contiene datos del lado frontal (específicos por tipo T2/T3) y datos MRZ del reverso
 * Implementa Parcelable para transferencia entre procesos Android
 */
public class CredentialResult implements Parcelable {
    // Datos del lado frontal - Comunes para T2 y T3
    private String nombre;
    private String domicilio;
    private String claveElector;
    private String curp;
    private String anoRegistro;
    private String fechaNacimiento;
    private String sexo;
    private String seccion;
    private String vigencia;
    
    // Datos del lado frontal - Específicos para T2
    private String estado;
    private String municipio;
    private String localidad;
    private String emision;
    
    // Datos del MRZ (lado reverso)
    private String mrzContent;
    private String mrzDocumentNumber;
    private String mrzNationality;
    private String mrzBirthDate;
    private String mrzExpiryDate;
    private String mrzSex;
    private String mrzName;
    
    // Metadatos del procesamiento
    private String documentSide;
    private String credentialType; // "T2" o "T3"
    private boolean isAcceptable;
    private long processingTimeMs;
    private String errorMessage;

    public CredentialResult() {
        // Constructor vacío
    }

    protected CredentialResult(Parcel in) {
        // Datos del lado frontal - Comunes
        nombre = in.readString();
        domicilio = in.readString();
        claveElector = in.readString();
        curp = in.readString();
        anoRegistro = in.readString();
        fechaNacimiento = in.readString();
        sexo = in.readString();
        seccion = in.readString();
        vigencia = in.readString();
        
        // Datos del lado frontal - Específicos T2
        estado = in.readString();
        municipio = in.readString();
        localidad = in.readString();
        emision = in.readString();
        
        // Datos del MRZ
        mrzContent = in.readString();
        mrzDocumentNumber = in.readString();
        mrzNationality = in.readString();
        mrzBirthDate = in.readString();
        mrzExpiryDate = in.readString();
        mrzSex = in.readString();
        mrzName = in.readString();
        
        // Metadatos
        documentSide = in.readString();
        credentialType = in.readString();
        isAcceptable = in.readByte() != 0;
        processingTimeMs = in.readLong();
        errorMessage = in.readString();
    }

    @Override
    public void writeToParcel(Parcel dest, int flags) {
        // Datos del lado frontal - Comunes
        dest.writeString(nombre);
        dest.writeString(domicilio);
        dest.writeString(claveElector);
        dest.writeString(curp);
        dest.writeString(anoRegistro);
        dest.writeString(fechaNacimiento);
        dest.writeString(sexo);
        dest.writeString(seccion);
        dest.writeString(vigencia);
        
        // Datos del lado frontal - Específicos T2
        dest.writeString(estado);
        dest.writeString(municipio);
        dest.writeString(localidad);
        dest.writeString(emision);
        
        // Datos del MRZ
        dest.writeString(mrzContent);
        dest.writeString(mrzDocumentNumber);
        dest.writeString(mrzNationality);
        dest.writeString(mrzBirthDate);
        dest.writeString(mrzExpiryDate);
        dest.writeString(mrzSex);
        dest.writeString(mrzName);
        
        // Metadatos
        dest.writeString(documentSide);
        dest.writeString(credentialType);
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
     * Convierte el resultado a JSON con todos los datos disponibles
     */
    public String toJson() {
        try {
            JSONObject json = new JSONObject();
            
            // Datos del lado frontal - Comunes para T2 y T3
            json.put("nombre", nombre != null ? nombre : "");
            json.put("domicilio", domicilio != null ? domicilio : "");
            json.put("claveElector", claveElector != null ? claveElector : "");
            json.put("curp", curp != null ? curp : "");
            json.put("anoRegistro", anoRegistro != null ? anoRegistro : "");
            json.put("fechaNacimiento", fechaNacimiento != null ? fechaNacimiento : "");
            json.put("sexo", sexo != null ? sexo : "");
            json.put("seccion", seccion != null ? seccion : "");
            json.put("vigencia", vigencia != null ? vigencia : "");
            
            // Datos del lado frontal - Específicos para T2 (opcionales para T3)
            json.put("estado", estado != null ? estado : "");
            json.put("municipio", municipio != null ? municipio : "");
            json.put("localidad", localidad != null ? localidad : "");
            json.put("emision", emision != null ? emision : "");
            
            // Datos del MRZ (lado reverso)
            JSONObject mrzData = new JSONObject();
            mrzData.put("content", mrzContent != null ? mrzContent : "");
            mrzData.put("documentNumber", mrzDocumentNumber != null ? mrzDocumentNumber : "");
            mrzData.put("nationality", mrzNationality != null ? mrzNationality : "");
            mrzData.put("birthDate", mrzBirthDate != null ? mrzBirthDate : "");
            mrzData.put("expiryDate", mrzExpiryDate != null ? mrzExpiryDate : "");
            mrzData.put("sex", mrzSex != null ? mrzSex : "");
            mrzData.put("name", mrzName != null ? mrzName : "");
            json.put("mrz", mrzData);
            
            // Metadatos
            json.put("documentSide", documentSide != null ? documentSide : "");
            json.put("credentialType", credentialType != null ? credentialType : "");
            json.put("isAcceptable", isAcceptable);
            json.put("processingTimeMs", processingTimeMs);
            json.put("errorMessage", errorMessage != null ? errorMessage : "");
            
            return json.toString();
        } catch (JSONException e) {
            return "{\"error\":\"Error serializando resultado: " + e.getMessage() + "\"}";
        }
    }

    /**
     * Crea un CredentialResult desde JSON
     */
    public static CredentialResult fromJson(String jsonString) {
        CredentialResult result = new CredentialResult();
        
        if (jsonString == null || jsonString.trim().isEmpty()) {
            result.setErrorMessage("JSON vacío o nulo");
            result.setAcceptable(false);
            return result;
        }
        
        try {
            JSONObject json = new JSONObject(jsonString);
            
            // Datos del lado frontal - Comunes para T2 y T3
            result.setNombre(json.optString("nombre", ""));
            result.setDomicilio(json.optString("domicilio", ""));
            result.setClaveElector(json.optString("claveElector", ""));
            result.setCurp(json.optString("curp", ""));
            result.setAnoRegistro(json.optString("anoRegistro", ""));
            result.setFechaNacimiento(json.optString("fechaNacimiento", ""));
            result.setSexo(json.optString("sexo", ""));
            result.setSeccion(json.optString("seccion", ""));
            result.setVigencia(json.optString("vigencia", ""));
            
            // Datos del lado frontal - Específicos para T2
            result.setEstado(json.optString("estado", ""));
            result.setMunicipio(json.optString("municipio", ""));
            result.setLocalidad(json.optString("localidad", ""));
            result.setEmision(json.optString("emision", ""));
            
            // Datos del MRZ
            if (json.has("mrz")) {
                JSONObject mrzData = json.getJSONObject("mrz");
                result.setMrzContent(mrzData.optString("content", ""));
                result.setMrzDocumentNumber(mrzData.optString("documentNumber", ""));
                result.setMrzNationality(mrzData.optString("nationality", ""));
                result.setMrzBirthDate(mrzData.optString("birthDate", ""));
                result.setMrzExpiryDate(mrzData.optString("expiryDate", ""));
                result.setMrzSex(mrzData.optString("sex", ""));
                result.setMrzName(mrzData.optString("name", ""));
            }
            
            // Metadatos
            result.setDocumentSide(json.optString("documentSide", ""));
            result.setCredentialType(json.optString("credentialType", ""));
            result.setAcceptable(json.optBoolean("isAcceptable", false));
            result.setProcessingTimeMs(json.optLong("processingTimeMs", 0));
            result.setErrorMessage(json.optString("errorMessage", ""));
            
        } catch (JSONException e) {
            result.setErrorMessage("Error parseando JSON: " + e.getMessage());
            result.setAcceptable(false);
        }
        
        return result;
    }

    // Getters y Setters
    
    // Datos del lado frontal - Comunes para T2 y T3
    public String getNombre() {
        return nombre;
    }

    public void setNombre(String nombre) {
        this.nombre = nombre;
    }

    public String getDomicilio() {
        return domicilio;
    }

    public void setDomicilio(String domicilio) {
        this.domicilio = domicilio;
    }

    public String getClaveElector() {
        return claveElector;
    }

    public void setClaveElector(String claveElector) {
        this.claveElector = claveElector;
    }

    public String getCurp() {
        return curp;
    }

    public void setCurp(String curp) {
        this.curp = curp;
    }

    public String getAnoRegistro() {
        return anoRegistro;
    }

    public void setAnoRegistro(String anoRegistro) {
        this.anoRegistro = anoRegistro;
    }

    public String getFechaNacimiento() {
        return fechaNacimiento;
    }

    public void setFechaNacimiento(String fechaNacimiento) {
        this.fechaNacimiento = fechaNacimiento;
    }

    public String getSexo() {
        return sexo;
    }

    public void setSexo(String sexo) {
        this.sexo = sexo;
    }

    public String getSeccion() {
        return seccion;
    }

    public void setSeccion(String seccion) {
        this.seccion = seccion;
    }

    public String getVigencia() {
        return vigencia;
    }

    public void setVigencia(String vigencia) {
        this.vigencia = vigencia;
    }

    // Datos del lado frontal - Específicos para T2
    public String getEstado() {
        return estado;
    }

    public void setEstado(String estado) {
        this.estado = estado;
    }

    public String getMunicipio() {
        return municipio;
    }

    public void setMunicipio(String municipio) {
        this.municipio = municipio;
    }

    public String getLocalidad() {
        return localidad;
    }

    public void setLocalidad(String localidad) {
        this.localidad = localidad;
    }

    public String getEmision() {
        return emision;
    }

    public void setEmision(String emision) {
        this.emision = emision;
    }

    // Datos del MRZ (lado reverso)
    public String getMrzContent() {
        return mrzContent;
    }

    public void setMrzContent(String mrzContent) {
        this.mrzContent = mrzContent;
    }

    public String getMrzDocumentNumber() {
        return mrzDocumentNumber;
    }

    public void setMrzDocumentNumber(String mrzDocumentNumber) {
        this.mrzDocumentNumber = mrzDocumentNumber;
    }

    public String getMrzNationality() {
        return mrzNationality;
    }

    public void setMrzNationality(String mrzNationality) {
        this.mrzNationality = mrzNationality;
    }

    public String getMrzBirthDate() {
        return mrzBirthDate;
    }

    public void setMrzBirthDate(String mrzBirthDate) {
        this.mrzBirthDate = mrzBirthDate;
    }

    public String getMrzExpiryDate() {
        return mrzExpiryDate;
    }

    public void setMrzExpiryDate(String mrzExpiryDate) {
        this.mrzExpiryDate = mrzExpiryDate;
    }

    public String getMrzSex() {
        return mrzSex;
    }

    public void setMrzSex(String mrzSex) {
        this.mrzSex = mrzSex;
    }

    public String getMrzName() {
        return mrzName;
    }

    public void setMrzName(String mrzName) {
        this.mrzName = mrzName;
    }

    public String getDocumentSide() {
        return documentSide;
    }

    public void setDocumentSide(String documentSide) {
        this.documentSide = documentSide;
    }

    public String getCredentialType() {
        return credentialType;
    }

    public void setCredentialType(String credentialType) {
        this.credentialType = credentialType;
    }

    public boolean isAcceptable() {
        return isAcceptable;
    }

    public void setAcceptable(boolean acceptable) {
        isAcceptable = acceptable;
    }

    public long getProcessingTimeMs() {
        return processingTimeMs;
    }

    public void setProcessingTimeMs(long processingTimeMs) {
        this.processingTimeMs = processingTimeMs;
    }

    public String getErrorMessage() {
        return errorMessage;
    }

    public void setErrorMessage(String errorMessage) {
        this.errorMessage = errorMessage;
    }

    @Override
    public String toString() {
        return "CredentialResult{" +
                "nombre='" + nombre + '\'' +
                ", domicilio='" + domicilio + '\'' +
                ", claveElector='" + claveElector + '\'' +
                ", curp='" + curp + '\'' +
                ", anoRegistro='" + anoRegistro + '\'' +
                ", fechaNacimiento='" + fechaNacimiento + '\'' +
                ", sexo='" + sexo + '\'' +
                ", seccion='" + seccion + '\'' +
                ", vigencia='" + vigencia + '\'' +
                ", estado='" + estado + '\'' +
                ", municipio='" + municipio + '\'' +
                ", localidad='" + localidad + '\'' +
                ", emision='" + emision + '\'' +
                ", mrzContent='" + mrzContent + '\'' +
                ", mrzDocumentNumber='" + mrzDocumentNumber + '\'' +
                ", mrzNationality='" + mrzNationality + '\'' +
                ", mrzBirthDate='" + mrzBirthDate + '\'' +
                ", mrzExpiryDate='" + mrzExpiryDate + '\'' +
                ", mrzSex='" + mrzSex + '\'' +
                ", mrzName='" + mrzName + '\'' +
                ", documentSide='" + documentSide + '\'' +
                ", credentialType='" + credentialType + '\'' +
                ", isAcceptable=" + isAcceptable +
                ", processingTimeMs=" + processingTimeMs +
                ", errorMessage='" + errorMessage + '\'' +
                '}';
    }
}