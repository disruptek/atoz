
import
  json, options, hashes, tables, openapi/rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon CloudSearch
## version: 2011-02-01
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>Amazon CloudSearch Configuration Service</fullname> <p>You use the configuration service to create, configure, and manage search domains. Configuration service requests are submitted using the AWS Query protocol. AWS Query requests are HTTP or HTTPS requests submitted via HTTP GET or POST with a query parameter named Action.</p> <p>The endpoint for configuration service requests is region-specific: cloudsearch.<i>region</i>.amazonaws.com. For example, cloudsearch.us-east-1.amazonaws.com. For a current list of supported regions and endpoints, see <a href="http://docs.aws.amazon.com/general/latest/gr/rande.html#cloudsearch_region">Regions and Endpoints</a>.</p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/cloudsearch/
type
  Scheme {.pure.} = enum
    Https = "https", Http = "http", Wss = "wss", Ws = "ws"
  ValidatorSignature = proc (query: JsonNode = nil; body: JsonNode = nil;
                          header: JsonNode = nil; path: JsonNode = nil;
                          formData: JsonNode = nil): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    url*: proc (protocol: Scheme; host: string; base: string; route: string;
              path: JsonNode): string

  OpenApiRestCall_772597 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_772597](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_772597): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low ..
      Scheme.high:
    if scheme notin t.schemes:
      continue
    if scheme in [Scheme.Https, Scheme.Wss]:
      when defined(ssl):
        return some(scheme)
      else:
        continue
    return some(scheme)

proc validateParameter(js: JsonNode; kind: JsonNodeKind; required: bool;
                      default: JsonNode = nil): JsonNode =
  ## ensure an input is of the correct json type and yield
  ## a suitable default value when appropriate
  if js ==
      nil:
    if default != nil:
      return validateParameter(default, kind, required = required)
  result = js
  if result ==
      nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind ==
        kind, $kind & " expected; received " &
        $js.kind

type
  KeyVal {.used.} = tuple[key: string, val: string]
  PathTokenKind = enum
    ConstantSegment, VariableSegment
  PathToken = tuple[kind: PathTokenKind, value: string]
proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] =
  ## reconstitute a path with constants and variable values taken from json
  var head: string
  if segments.len == 0:
    return some("")
  head = segments[0].value
  case segments[0].kind
  of ConstantSegment:
    discard
  of VariableSegment:
    if head notin input:
      return
    let js = input[head]
    if js.kind notin {JString, JInt, JFloat, JNull, JBool}:
      return
    head = $js
  var remainder = input.hydratePath(segments[1 ..^ 1])
  if remainder.isNone:
    return
  result = some(head & remainder.get())

const
  awsServers = {Scheme.Http: {"ap-northeast-1": "cloudsearch.ap-northeast-1.amazonaws.com", "ap-southeast-1": "cloudsearch.ap-southeast-1.amazonaws.com",
                           "us-west-2": "cloudsearch.us-west-2.amazonaws.com",
                           "eu-west-2": "cloudsearch.eu-west-2.amazonaws.com", "ap-northeast-3": "cloudsearch.ap-northeast-3.amazonaws.com", "eu-central-1": "cloudsearch.eu-central-1.amazonaws.com",
                           "us-east-2": "cloudsearch.us-east-2.amazonaws.com",
                           "us-east-1": "cloudsearch.us-east-1.amazonaws.com", "cn-northwest-1": "cloudsearch.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "cloudsearch.ap-south-1.amazonaws.com", "eu-north-1": "cloudsearch.eu-north-1.amazonaws.com", "ap-northeast-2": "cloudsearch.ap-northeast-2.amazonaws.com",
                           "us-west-1": "cloudsearch.us-west-1.amazonaws.com", "us-gov-east-1": "cloudsearch.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "cloudsearch.eu-west-3.amazonaws.com", "cn-north-1": "cloudsearch.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "cloudsearch.sa-east-1.amazonaws.com",
                           "eu-west-1": "cloudsearch.eu-west-1.amazonaws.com", "us-gov-west-1": "cloudsearch.us-gov-west-1.amazonaws.com", "ap-southeast-2": "cloudsearch.ap-southeast-2.amazonaws.com", "ca-central-1": "cloudsearch.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "cloudsearch.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "cloudsearch.ap-southeast-1.amazonaws.com",
      "us-west-2": "cloudsearch.us-west-2.amazonaws.com",
      "eu-west-2": "cloudsearch.eu-west-2.amazonaws.com",
      "ap-northeast-3": "cloudsearch.ap-northeast-3.amazonaws.com",
      "eu-central-1": "cloudsearch.eu-central-1.amazonaws.com",
      "us-east-2": "cloudsearch.us-east-2.amazonaws.com",
      "us-east-1": "cloudsearch.us-east-1.amazonaws.com",
      "cn-northwest-1": "cloudsearch.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "cloudsearch.ap-south-1.amazonaws.com",
      "eu-north-1": "cloudsearch.eu-north-1.amazonaws.com",
      "ap-northeast-2": "cloudsearch.ap-northeast-2.amazonaws.com",
      "us-west-1": "cloudsearch.us-west-1.amazonaws.com",
      "us-gov-east-1": "cloudsearch.us-gov-east-1.amazonaws.com",
      "eu-west-3": "cloudsearch.eu-west-3.amazonaws.com",
      "cn-north-1": "cloudsearch.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "cloudsearch.sa-east-1.amazonaws.com",
      "eu-west-1": "cloudsearch.eu-west-1.amazonaws.com",
      "us-gov-west-1": "cloudsearch.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "cloudsearch.ap-southeast-2.amazonaws.com",
      "ca-central-1": "cloudsearch.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "cloudsearch"
method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.}
type
  Call_PostCreateDomain_773204 = ref object of OpenApiRestCall_772597
proc url_PostCreateDomain_773206(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateDomain_773205(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Creates a new search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773207 = query.getOrDefault("Action")
  valid_773207 = validateParameter(valid_773207, JString, required = true,
                                 default = newJString("CreateDomain"))
  if valid_773207 != nil:
    section.add "Action", valid_773207
  var valid_773208 = query.getOrDefault("Version")
  valid_773208 = validateParameter(valid_773208, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_773208 != nil:
    section.add "Version", valid_773208
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773209 = header.getOrDefault("X-Amz-Date")
  valid_773209 = validateParameter(valid_773209, JString, required = false,
                                 default = nil)
  if valid_773209 != nil:
    section.add "X-Amz-Date", valid_773209
  var valid_773210 = header.getOrDefault("X-Amz-Security-Token")
  valid_773210 = validateParameter(valid_773210, JString, required = false,
                                 default = nil)
  if valid_773210 != nil:
    section.add "X-Amz-Security-Token", valid_773210
  var valid_773211 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773211 = validateParameter(valid_773211, JString, required = false,
                                 default = nil)
  if valid_773211 != nil:
    section.add "X-Amz-Content-Sha256", valid_773211
  var valid_773212 = header.getOrDefault("X-Amz-Algorithm")
  valid_773212 = validateParameter(valid_773212, JString, required = false,
                                 default = nil)
  if valid_773212 != nil:
    section.add "X-Amz-Algorithm", valid_773212
  var valid_773213 = header.getOrDefault("X-Amz-Signature")
  valid_773213 = validateParameter(valid_773213, JString, required = false,
                                 default = nil)
  if valid_773213 != nil:
    section.add "X-Amz-Signature", valid_773213
  var valid_773214 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773214 = validateParameter(valid_773214, JString, required = false,
                                 default = nil)
  if valid_773214 != nil:
    section.add "X-Amz-SignedHeaders", valid_773214
  var valid_773215 = header.getOrDefault("X-Amz-Credential")
  valid_773215 = validateParameter(valid_773215, JString, required = false,
                                 default = nil)
  if valid_773215 != nil:
    section.add "X-Amz-Credential", valid_773215
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_773216 = formData.getOrDefault("DomainName")
  valid_773216 = validateParameter(valid_773216, JString, required = true,
                                 default = nil)
  if valid_773216 != nil:
    section.add "DomainName", valid_773216
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773217: Call_PostCreateDomain_773204; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new search domain.
  ## 
  let valid = call_773217.validator(path, query, header, formData, body)
  let scheme = call_773217.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773217.url(scheme.get, call_773217.host, call_773217.base,
                         call_773217.route, valid.getOrDefault("path"))
  result = hook(call_773217, url, valid)

proc call*(call_773218: Call_PostCreateDomain_773204; DomainName: string;
          Action: string = "CreateDomain"; Version: string = "2011-02-01"): Recallable =
  ## postCreateDomain
  ## Creates a new search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773219 = newJObject()
  var formData_773220 = newJObject()
  add(formData_773220, "DomainName", newJString(DomainName))
  add(query_773219, "Action", newJString(Action))
  add(query_773219, "Version", newJString(Version))
  result = call_773218.call(nil, query_773219, nil, formData_773220, nil)

var postCreateDomain* = Call_PostCreateDomain_773204(name: "postCreateDomain",
    meth: HttpMethod.HttpPost, host: "cloudsearch.amazonaws.com",
    route: "/#Action=CreateDomain", validator: validate_PostCreateDomain_773205,
    base: "/", url: url_PostCreateDomain_773206,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDomain_772933 = ref object of OpenApiRestCall_772597
proc url_GetCreateDomain_772935(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateDomain_772934(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Creates a new search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773060 = query.getOrDefault("Action")
  valid_773060 = validateParameter(valid_773060, JString, required = true,
                                 default = newJString("CreateDomain"))
  if valid_773060 != nil:
    section.add "Action", valid_773060
  var valid_773061 = query.getOrDefault("DomainName")
  valid_773061 = validateParameter(valid_773061, JString, required = true,
                                 default = nil)
  if valid_773061 != nil:
    section.add "DomainName", valid_773061
  var valid_773062 = query.getOrDefault("Version")
  valid_773062 = validateParameter(valid_773062, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_773062 != nil:
    section.add "Version", valid_773062
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773063 = header.getOrDefault("X-Amz-Date")
  valid_773063 = validateParameter(valid_773063, JString, required = false,
                                 default = nil)
  if valid_773063 != nil:
    section.add "X-Amz-Date", valid_773063
  var valid_773064 = header.getOrDefault("X-Amz-Security-Token")
  valid_773064 = validateParameter(valid_773064, JString, required = false,
                                 default = nil)
  if valid_773064 != nil:
    section.add "X-Amz-Security-Token", valid_773064
  var valid_773065 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773065 = validateParameter(valid_773065, JString, required = false,
                                 default = nil)
  if valid_773065 != nil:
    section.add "X-Amz-Content-Sha256", valid_773065
  var valid_773066 = header.getOrDefault("X-Amz-Algorithm")
  valid_773066 = validateParameter(valid_773066, JString, required = false,
                                 default = nil)
  if valid_773066 != nil:
    section.add "X-Amz-Algorithm", valid_773066
  var valid_773067 = header.getOrDefault("X-Amz-Signature")
  valid_773067 = validateParameter(valid_773067, JString, required = false,
                                 default = nil)
  if valid_773067 != nil:
    section.add "X-Amz-Signature", valid_773067
  var valid_773068 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773068 = validateParameter(valid_773068, JString, required = false,
                                 default = nil)
  if valid_773068 != nil:
    section.add "X-Amz-SignedHeaders", valid_773068
  var valid_773069 = header.getOrDefault("X-Amz-Credential")
  valid_773069 = validateParameter(valid_773069, JString, required = false,
                                 default = nil)
  if valid_773069 != nil:
    section.add "X-Amz-Credential", valid_773069
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773092: Call_GetCreateDomain_772933; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new search domain.
  ## 
  let valid = call_773092.validator(path, query, header, formData, body)
  let scheme = call_773092.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773092.url(scheme.get, call_773092.host, call_773092.base,
                         call_773092.route, valid.getOrDefault("path"))
  result = hook(call_773092, url, valid)

proc call*(call_773163: Call_GetCreateDomain_772933; DomainName: string;
          Action: string = "CreateDomain"; Version: string = "2011-02-01"): Recallable =
  ## getCreateDomain
  ## Creates a new search domain.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_773164 = newJObject()
  add(query_773164, "Action", newJString(Action))
  add(query_773164, "DomainName", newJString(DomainName))
  add(query_773164, "Version", newJString(Version))
  result = call_773163.call(nil, query_773164, nil, nil, nil)

var getCreateDomain* = Call_GetCreateDomain_772933(name: "getCreateDomain",
    meth: HttpMethod.HttpGet, host: "cloudsearch.amazonaws.com",
    route: "/#Action=CreateDomain", validator: validate_GetCreateDomain_772934,
    base: "/", url: url_GetCreateDomain_772935, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDefineIndexField_773243 = ref object of OpenApiRestCall_772597
proc url_PostDefineIndexField_773245(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDefineIndexField_773244(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures an <code>IndexField</code> for the search domain. Used to create new fields and modify existing ones. If the field exists, the new configuration replaces the old one. You can configure a maximum of 200 index fields.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773246 = query.getOrDefault("Action")
  valid_773246 = validateParameter(valid_773246, JString, required = true,
                                 default = newJString("DefineIndexField"))
  if valid_773246 != nil:
    section.add "Action", valid_773246
  var valid_773247 = query.getOrDefault("Version")
  valid_773247 = validateParameter(valid_773247, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_773247 != nil:
    section.add "Version", valid_773247
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773248 = header.getOrDefault("X-Amz-Date")
  valid_773248 = validateParameter(valid_773248, JString, required = false,
                                 default = nil)
  if valid_773248 != nil:
    section.add "X-Amz-Date", valid_773248
  var valid_773249 = header.getOrDefault("X-Amz-Security-Token")
  valid_773249 = validateParameter(valid_773249, JString, required = false,
                                 default = nil)
  if valid_773249 != nil:
    section.add "X-Amz-Security-Token", valid_773249
  var valid_773250 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773250 = validateParameter(valid_773250, JString, required = false,
                                 default = nil)
  if valid_773250 != nil:
    section.add "X-Amz-Content-Sha256", valid_773250
  var valid_773251 = header.getOrDefault("X-Amz-Algorithm")
  valid_773251 = validateParameter(valid_773251, JString, required = false,
                                 default = nil)
  if valid_773251 != nil:
    section.add "X-Amz-Algorithm", valid_773251
  var valid_773252 = header.getOrDefault("X-Amz-Signature")
  valid_773252 = validateParameter(valid_773252, JString, required = false,
                                 default = nil)
  if valid_773252 != nil:
    section.add "X-Amz-Signature", valid_773252
  var valid_773253 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773253 = validateParameter(valid_773253, JString, required = false,
                                 default = nil)
  if valid_773253 != nil:
    section.add "X-Amz-SignedHeaders", valid_773253
  var valid_773254 = header.getOrDefault("X-Amz-Credential")
  valid_773254 = validateParameter(valid_773254, JString, required = false,
                                 default = nil)
  if valid_773254 != nil:
    section.add "X-Amz-Credential", valid_773254
  result.add "header", section
  ## parameters in `formData` object:
  ##   IndexField.UIntOptions: JString
  ##                         : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for an unsigned integer field. Present if <code>IndexFieldType</code> specifies the field is of type unsigned integer.
  ##   IndexField.TextOptions: JString
  ##                         : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for text field. Present if <code>IndexFieldType</code> specifies the field is of type text.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   IndexField.LiteralOptions: JString
  ##                            : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for literal field. Present if <code>IndexFieldType</code> specifies the field is of type literal.
  ##   IndexField.IndexFieldType: JString
  ##                            : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## The type of field. Based on this type, exactly one of the <a>UIntOptions</a>, <a>LiteralOptions</a> or <a>TextOptions</a> must be present.
  ##   IndexField.IndexFieldName: JString
  ##                            : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## The name of a field in the search index. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   IndexField.SourceAttributes: JArray
  ##                              : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## An optional list of source attributes that provide data for this index field. If not specified, the data is pulled from a source attribute with the same name as this <code>IndexField</code>. When one or more source attributes are specified, an optional data transformation can be applied to the source data when populating the index field. You can configure a maximum of 20 sources for an <code>IndexField</code>.
  section = newJObject()
  var valid_773255 = formData.getOrDefault("IndexField.UIntOptions")
  valid_773255 = validateParameter(valid_773255, JString, required = false,
                                 default = nil)
  if valid_773255 != nil:
    section.add "IndexField.UIntOptions", valid_773255
  var valid_773256 = formData.getOrDefault("IndexField.TextOptions")
  valid_773256 = validateParameter(valid_773256, JString, required = false,
                                 default = nil)
  if valid_773256 != nil:
    section.add "IndexField.TextOptions", valid_773256
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_773257 = formData.getOrDefault("DomainName")
  valid_773257 = validateParameter(valid_773257, JString, required = true,
                                 default = nil)
  if valid_773257 != nil:
    section.add "DomainName", valid_773257
  var valid_773258 = formData.getOrDefault("IndexField.LiteralOptions")
  valid_773258 = validateParameter(valid_773258, JString, required = false,
                                 default = nil)
  if valid_773258 != nil:
    section.add "IndexField.LiteralOptions", valid_773258
  var valid_773259 = formData.getOrDefault("IndexField.IndexFieldType")
  valid_773259 = validateParameter(valid_773259, JString, required = false,
                                 default = nil)
  if valid_773259 != nil:
    section.add "IndexField.IndexFieldType", valid_773259
  var valid_773260 = formData.getOrDefault("IndexField.IndexFieldName")
  valid_773260 = validateParameter(valid_773260, JString, required = false,
                                 default = nil)
  if valid_773260 != nil:
    section.add "IndexField.IndexFieldName", valid_773260
  var valid_773261 = formData.getOrDefault("IndexField.SourceAttributes")
  valid_773261 = validateParameter(valid_773261, JArray, required = false,
                                 default = nil)
  if valid_773261 != nil:
    section.add "IndexField.SourceAttributes", valid_773261
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773262: Call_PostDefineIndexField_773243; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures an <code>IndexField</code> for the search domain. Used to create new fields and modify existing ones. If the field exists, the new configuration replaces the old one. You can configure a maximum of 200 index fields.
  ## 
  let valid = call_773262.validator(path, query, header, formData, body)
  let scheme = call_773262.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773262.url(scheme.get, call_773262.host, call_773262.base,
                         call_773262.route, valid.getOrDefault("path"))
  result = hook(call_773262, url, valid)

proc call*(call_773263: Call_PostDefineIndexField_773243; DomainName: string;
          IndexFieldUIntOptions: string = ""; IndexFieldTextOptions: string = "";
          IndexFieldLiteralOptions: string = "";
          IndexFieldIndexFieldType: string = "";
          Action: string = "DefineIndexField";
          IndexFieldIndexFieldName: string = ""; Version: string = "2011-02-01";
          IndexFieldSourceAttributes: JsonNode = nil): Recallable =
  ## postDefineIndexField
  ## Configures an <code>IndexField</code> for the search domain. Used to create new fields and modify existing ones. If the field exists, the new configuration replaces the old one. You can configure a maximum of 200 index fields.
  ##   IndexFieldUIntOptions: string
  ##                        : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for an unsigned integer field. Present if <code>IndexFieldType</code> specifies the field is of type unsigned integer.
  ##   IndexFieldTextOptions: string
  ##                        : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for text field. Present if <code>IndexFieldType</code> specifies the field is of type text.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   IndexFieldLiteralOptions: string
  ##                           : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for literal field. Present if <code>IndexFieldType</code> specifies the field is of type literal.
  ##   IndexFieldIndexFieldType: string
  ##                           : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## The type of field. Based on this type, exactly one of the <a>UIntOptions</a>, <a>LiteralOptions</a> or <a>TextOptions</a> must be present.
  ##   Action: string (required)
  ##   IndexFieldIndexFieldName: string
  ##                           : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## The name of a field in the search index. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   Version: string (required)
  ##   IndexFieldSourceAttributes: JArray
  ##                             : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## An optional list of source attributes that provide data for this index field. If not specified, the data is pulled from a source attribute with the same name as this <code>IndexField</code>. When one or more source attributes are specified, an optional data transformation can be applied to the source data when populating the index field. You can configure a maximum of 20 sources for an <code>IndexField</code>.
  var query_773264 = newJObject()
  var formData_773265 = newJObject()
  add(formData_773265, "IndexField.UIntOptions", newJString(IndexFieldUIntOptions))
  add(formData_773265, "IndexField.TextOptions", newJString(IndexFieldTextOptions))
  add(formData_773265, "DomainName", newJString(DomainName))
  add(formData_773265, "IndexField.LiteralOptions",
      newJString(IndexFieldLiteralOptions))
  add(formData_773265, "IndexField.IndexFieldType",
      newJString(IndexFieldIndexFieldType))
  add(query_773264, "Action", newJString(Action))
  add(formData_773265, "IndexField.IndexFieldName",
      newJString(IndexFieldIndexFieldName))
  add(query_773264, "Version", newJString(Version))
  if IndexFieldSourceAttributes != nil:
    formData_773265.add "IndexField.SourceAttributes", IndexFieldSourceAttributes
  result = call_773263.call(nil, query_773264, nil, formData_773265, nil)

var postDefineIndexField* = Call_PostDefineIndexField_773243(
    name: "postDefineIndexField", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineIndexField",
    validator: validate_PostDefineIndexField_773244, base: "/",
    url: url_PostDefineIndexField_773245, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDefineIndexField_773221 = ref object of OpenApiRestCall_772597
proc url_GetDefineIndexField_773223(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDefineIndexField_773222(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Configures an <code>IndexField</code> for the search domain. Used to create new fields and modify existing ones. If the field exists, the new configuration replaces the old one. You can configure a maximum of 200 index fields.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   IndexField.TextOptions: JString
  ##                         : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for text field. Present if <code>IndexFieldType</code> specifies the field is of type text.
  ##   IndexField.LiteralOptions: JString
  ##                            : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for literal field. Present if <code>IndexFieldType</code> specifies the field is of type literal.
  ##   IndexField.UIntOptions: JString
  ##                         : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for an unsigned integer field. Present if <code>IndexFieldType</code> specifies the field is of type unsigned integer.
  ##   IndexField.IndexFieldType: JString
  ##                            : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## The type of field. Based on this type, exactly one of the <a>UIntOptions</a>, <a>LiteralOptions</a> or <a>TextOptions</a> must be present.
  ##   IndexField.SourceAttributes: JArray
  ##                              : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## An optional list of source attributes that provide data for this index field. If not specified, the data is pulled from a source attribute with the same name as this <code>IndexField</code>. When one or more source attributes are specified, an optional data transformation can be applied to the source data when populating the index field. You can configure a maximum of 20 sources for an <code>IndexField</code>.
  ##   IndexField.IndexFieldName: JString
  ##                            : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## The name of a field in the search index. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: JString (required)
  section = newJObject()
  var valid_773224 = query.getOrDefault("IndexField.TextOptions")
  valid_773224 = validateParameter(valid_773224, JString, required = false,
                                 default = nil)
  if valid_773224 != nil:
    section.add "IndexField.TextOptions", valid_773224
  var valid_773225 = query.getOrDefault("IndexField.LiteralOptions")
  valid_773225 = validateParameter(valid_773225, JString, required = false,
                                 default = nil)
  if valid_773225 != nil:
    section.add "IndexField.LiteralOptions", valid_773225
  var valid_773226 = query.getOrDefault("IndexField.UIntOptions")
  valid_773226 = validateParameter(valid_773226, JString, required = false,
                                 default = nil)
  if valid_773226 != nil:
    section.add "IndexField.UIntOptions", valid_773226
  var valid_773227 = query.getOrDefault("IndexField.IndexFieldType")
  valid_773227 = validateParameter(valid_773227, JString, required = false,
                                 default = nil)
  if valid_773227 != nil:
    section.add "IndexField.IndexFieldType", valid_773227
  var valid_773228 = query.getOrDefault("IndexField.SourceAttributes")
  valid_773228 = validateParameter(valid_773228, JArray, required = false,
                                 default = nil)
  if valid_773228 != nil:
    section.add "IndexField.SourceAttributes", valid_773228
  var valid_773229 = query.getOrDefault("IndexField.IndexFieldName")
  valid_773229 = validateParameter(valid_773229, JString, required = false,
                                 default = nil)
  if valid_773229 != nil:
    section.add "IndexField.IndexFieldName", valid_773229
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773230 = query.getOrDefault("Action")
  valid_773230 = validateParameter(valid_773230, JString, required = true,
                                 default = newJString("DefineIndexField"))
  if valid_773230 != nil:
    section.add "Action", valid_773230
  var valid_773231 = query.getOrDefault("DomainName")
  valid_773231 = validateParameter(valid_773231, JString, required = true,
                                 default = nil)
  if valid_773231 != nil:
    section.add "DomainName", valid_773231
  var valid_773232 = query.getOrDefault("Version")
  valid_773232 = validateParameter(valid_773232, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_773232 != nil:
    section.add "Version", valid_773232
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773233 = header.getOrDefault("X-Amz-Date")
  valid_773233 = validateParameter(valid_773233, JString, required = false,
                                 default = nil)
  if valid_773233 != nil:
    section.add "X-Amz-Date", valid_773233
  var valid_773234 = header.getOrDefault("X-Amz-Security-Token")
  valid_773234 = validateParameter(valid_773234, JString, required = false,
                                 default = nil)
  if valid_773234 != nil:
    section.add "X-Amz-Security-Token", valid_773234
  var valid_773235 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773235 = validateParameter(valid_773235, JString, required = false,
                                 default = nil)
  if valid_773235 != nil:
    section.add "X-Amz-Content-Sha256", valid_773235
  var valid_773236 = header.getOrDefault("X-Amz-Algorithm")
  valid_773236 = validateParameter(valid_773236, JString, required = false,
                                 default = nil)
  if valid_773236 != nil:
    section.add "X-Amz-Algorithm", valid_773236
  var valid_773237 = header.getOrDefault("X-Amz-Signature")
  valid_773237 = validateParameter(valid_773237, JString, required = false,
                                 default = nil)
  if valid_773237 != nil:
    section.add "X-Amz-Signature", valid_773237
  var valid_773238 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773238 = validateParameter(valid_773238, JString, required = false,
                                 default = nil)
  if valid_773238 != nil:
    section.add "X-Amz-SignedHeaders", valid_773238
  var valid_773239 = header.getOrDefault("X-Amz-Credential")
  valid_773239 = validateParameter(valid_773239, JString, required = false,
                                 default = nil)
  if valid_773239 != nil:
    section.add "X-Amz-Credential", valid_773239
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773240: Call_GetDefineIndexField_773221; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures an <code>IndexField</code> for the search domain. Used to create new fields and modify existing ones. If the field exists, the new configuration replaces the old one. You can configure a maximum of 200 index fields.
  ## 
  let valid = call_773240.validator(path, query, header, formData, body)
  let scheme = call_773240.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773240.url(scheme.get, call_773240.host, call_773240.base,
                         call_773240.route, valid.getOrDefault("path"))
  result = hook(call_773240, url, valid)

proc call*(call_773241: Call_GetDefineIndexField_773221; DomainName: string;
          IndexFieldTextOptions: string = ""; IndexFieldLiteralOptions: string = "";
          IndexFieldUIntOptions: string = ""; IndexFieldIndexFieldType: string = "";
          IndexFieldSourceAttributes: JsonNode = nil;
          IndexFieldIndexFieldName: string = "";
          Action: string = "DefineIndexField"; Version: string = "2011-02-01"): Recallable =
  ## getDefineIndexField
  ## Configures an <code>IndexField</code> for the search domain. Used to create new fields and modify existing ones. If the field exists, the new configuration replaces the old one. You can configure a maximum of 200 index fields.
  ##   IndexFieldTextOptions: string
  ##                        : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for text field. Present if <code>IndexFieldType</code> specifies the field is of type text.
  ##   IndexFieldLiteralOptions: string
  ##                           : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for literal field. Present if <code>IndexFieldType</code> specifies the field is of type literal.
  ##   IndexFieldUIntOptions: string
  ##                        : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for an unsigned integer field. Present if <code>IndexFieldType</code> specifies the field is of type unsigned integer.
  ##   IndexFieldIndexFieldType: string
  ##                           : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## The type of field. Based on this type, exactly one of the <a>UIntOptions</a>, <a>LiteralOptions</a> or <a>TextOptions</a> must be present.
  ##   IndexFieldSourceAttributes: JArray
  ##                             : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## An optional list of source attributes that provide data for this index field. If not specified, the data is pulled from a source attribute with the same name as this <code>IndexField</code>. When one or more source attributes are specified, an optional data transformation can be applied to the source data when populating the index field. You can configure a maximum of 20 sources for an <code>IndexField</code>.
  ##   IndexFieldIndexFieldName: string
  ##                           : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## The name of a field in the search index. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_773242 = newJObject()
  add(query_773242, "IndexField.TextOptions", newJString(IndexFieldTextOptions))
  add(query_773242, "IndexField.LiteralOptions",
      newJString(IndexFieldLiteralOptions))
  add(query_773242, "IndexField.UIntOptions", newJString(IndexFieldUIntOptions))
  add(query_773242, "IndexField.IndexFieldType",
      newJString(IndexFieldIndexFieldType))
  if IndexFieldSourceAttributes != nil:
    query_773242.add "IndexField.SourceAttributes", IndexFieldSourceAttributes
  add(query_773242, "IndexField.IndexFieldName",
      newJString(IndexFieldIndexFieldName))
  add(query_773242, "Action", newJString(Action))
  add(query_773242, "DomainName", newJString(DomainName))
  add(query_773242, "Version", newJString(Version))
  result = call_773241.call(nil, query_773242, nil, nil, nil)

var getDefineIndexField* = Call_GetDefineIndexField_773221(
    name: "getDefineIndexField", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineIndexField",
    validator: validate_GetDefineIndexField_773222, base: "/",
    url: url_GetDefineIndexField_773223, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDefineRankExpression_773284 = ref object of OpenApiRestCall_772597
proc url_PostDefineRankExpression_773286(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDefineRankExpression_773285(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures a <code>RankExpression</code> for the search domain. Used to create new rank expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. You can configure a maximum of 50 rank expressions.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773287 = query.getOrDefault("Action")
  valid_773287 = validateParameter(valid_773287, JString, required = true,
                                 default = newJString("DefineRankExpression"))
  if valid_773287 != nil:
    section.add "Action", valid_773287
  var valid_773288 = query.getOrDefault("Version")
  valid_773288 = validateParameter(valid_773288, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_773288 != nil:
    section.add "Version", valid_773288
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773289 = header.getOrDefault("X-Amz-Date")
  valid_773289 = validateParameter(valid_773289, JString, required = false,
                                 default = nil)
  if valid_773289 != nil:
    section.add "X-Amz-Date", valid_773289
  var valid_773290 = header.getOrDefault("X-Amz-Security-Token")
  valid_773290 = validateParameter(valid_773290, JString, required = false,
                                 default = nil)
  if valid_773290 != nil:
    section.add "X-Amz-Security-Token", valid_773290
  var valid_773291 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773291 = validateParameter(valid_773291, JString, required = false,
                                 default = nil)
  if valid_773291 != nil:
    section.add "X-Amz-Content-Sha256", valid_773291
  var valid_773292 = header.getOrDefault("X-Amz-Algorithm")
  valid_773292 = validateParameter(valid_773292, JString, required = false,
                                 default = nil)
  if valid_773292 != nil:
    section.add "X-Amz-Algorithm", valid_773292
  var valid_773293 = header.getOrDefault("X-Amz-Signature")
  valid_773293 = validateParameter(valid_773293, JString, required = false,
                                 default = nil)
  if valid_773293 != nil:
    section.add "X-Amz-Signature", valid_773293
  var valid_773294 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773294 = validateParameter(valid_773294, JString, required = false,
                                 default = nil)
  if valid_773294 != nil:
    section.add "X-Amz-SignedHeaders", valid_773294
  var valid_773295 = header.getOrDefault("X-Amz-Credential")
  valid_773295 = validateParameter(valid_773295, JString, required = false,
                                 default = nil)
  if valid_773295 != nil:
    section.add "X-Amz-Credential", valid_773295
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   RankExpression.RankName: JString
  ##                          : A named expression that can be evaluated at search time and used for ranking or thresholding in a search query. 
  ## The name of a rank expression. Rank expression names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   RankExpression.RankExpression: JString
  ##                                : A named expression that can be evaluated at search time and used for ranking or thresholding in a search query. 
  ## <p>The expression to evaluate for ranking or thresholding while processing a search request. The <code>RankExpression</code> syntax is based on JavaScript expressions and supports:</p> <ul> <li>Integer, floating point, hex and octal literals</li> <li>Shortcut evaluation of logical operators such that an expression <code>a || b</code> evaluates to the value <code>a</code>, if <code>a</code> is true, without evaluating <code>b</code> at all</li> <li>JavaScript order of precedence for operators</li> <li>Arithmetic operators: <code>+ - * / %</code> </li> <li>Boolean operators (including the ternary operator)</li> <li>Bitwise operators</li> <li>Comparison operators</li> <li>Common mathematic functions: <code>abs ceil erf exp floor lgamma ln log2 log10 max min sqrt pow</code> </li> <li>Trigonometric library functions: <code>acosh acos asinh asin atanh atan cosh cos sinh sin tanh tan</code> </li> <li>Random generation of a number between 0 and 1: <code>rand</code> </li> <li>Current time in epoch: <code>time</code> </li> <li>The <code>min max</code> functions that operate on a variable argument list</li> </ul> <p>Intermediate results are calculated as double precision floating point values. The final return value of a <code>RankExpression</code> is automatically converted from floating point to a 32-bit unsigned integer by rounding to the nearest integer, with a natural floor of 0 and a ceiling of max(uint32_t), 4294967295. Mathematical errors such as dividing by 0 will fail during evaluation and return a value of 0.</p> <p>The source data for a <code>RankExpression</code> can be the name of an <code>IndexField</code> of type uint, another <code>RankExpression</code> or the reserved name <i>text_relevance</i>. The text_relevance source is defined to return an integer from 0 to 1000 (inclusive) to indicate how relevant a document is to the search request, taking into account repetition of search terms in the document and proximity of search terms to each other in each matching <code>IndexField</code> in the document.</p> <p>For more information about using rank expressions to customize ranking, see the Amazon CloudSearch Developer Guide.</p>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_773296 = formData.getOrDefault("DomainName")
  valid_773296 = validateParameter(valid_773296, JString, required = true,
                                 default = nil)
  if valid_773296 != nil:
    section.add "DomainName", valid_773296
  var valid_773297 = formData.getOrDefault("RankExpression.RankName")
  valid_773297 = validateParameter(valid_773297, JString, required = false,
                                 default = nil)
  if valid_773297 != nil:
    section.add "RankExpression.RankName", valid_773297
  var valid_773298 = formData.getOrDefault("RankExpression.RankExpression")
  valid_773298 = validateParameter(valid_773298, JString, required = false,
                                 default = nil)
  if valid_773298 != nil:
    section.add "RankExpression.RankExpression", valid_773298
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773299: Call_PostDefineRankExpression_773284; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a <code>RankExpression</code> for the search domain. Used to create new rank expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. You can configure a maximum of 50 rank expressions.
  ## 
  let valid = call_773299.validator(path, query, header, formData, body)
  let scheme = call_773299.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773299.url(scheme.get, call_773299.host, call_773299.base,
                         call_773299.route, valid.getOrDefault("path"))
  result = hook(call_773299, url, valid)

proc call*(call_773300: Call_PostDefineRankExpression_773284; DomainName: string;
          RankExpressionRankName: string = "";
          RankExpressionRankExpression: string = "";
          Action: string = "DefineRankExpression"; Version: string = "2011-02-01"): Recallable =
  ## postDefineRankExpression
  ## Configures a <code>RankExpression</code> for the search domain. Used to create new rank expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. You can configure a maximum of 50 rank expressions.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   RankExpressionRankName: string
  ##                         : A named expression that can be evaluated at search time and used for ranking or thresholding in a search query. 
  ## The name of a rank expression. Rank expression names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   RankExpressionRankExpression: string
  ##                               : A named expression that can be evaluated at search time and used for ranking or thresholding in a search query. 
  ## <p>The expression to evaluate for ranking or thresholding while processing a search request. The <code>RankExpression</code> syntax is based on JavaScript expressions and supports:</p> <ul> <li>Integer, floating point, hex and octal literals</li> <li>Shortcut evaluation of logical operators such that an expression <code>a || b</code> evaluates to the value <code>a</code>, if <code>a</code> is true, without evaluating <code>b</code> at all</li> <li>JavaScript order of precedence for operators</li> <li>Arithmetic operators: <code>+ - * / %</code> </li> <li>Boolean operators (including the ternary operator)</li> <li>Bitwise operators</li> <li>Comparison operators</li> <li>Common mathematic functions: <code>abs ceil erf exp floor lgamma ln log2 log10 max min sqrt pow</code> </li> <li>Trigonometric library functions: <code>acosh acos asinh asin atanh atan cosh cos sinh sin tanh tan</code> </li> <li>Random generation of a number between 0 and 1: <code>rand</code> </li> <li>Current time in epoch: <code>time</code> </li> <li>The <code>min max</code> functions that operate on a variable argument list</li> </ul> <p>Intermediate results are calculated as double precision floating point values. The final return value of a <code>RankExpression</code> is automatically converted from floating point to a 32-bit unsigned integer by rounding to the nearest integer, with a natural floor of 0 and a ceiling of max(uint32_t), 4294967295. Mathematical errors such as dividing by 0 will fail during evaluation and return a value of 0.</p> <p>The source data for a <code>RankExpression</code> can be the name of an <code>IndexField</code> of type uint, another <code>RankExpression</code> or the reserved name <i>text_relevance</i>. The text_relevance source is defined to return an integer from 0 to 1000 (inclusive) to indicate how relevant a document is to the search request, taking into account repetition of search terms in the document and proximity of search terms to each other in each matching <code>IndexField</code> in the document.</p> <p>For more information about using rank expressions to customize ranking, see the Amazon CloudSearch Developer Guide.</p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773301 = newJObject()
  var formData_773302 = newJObject()
  add(formData_773302, "DomainName", newJString(DomainName))
  add(formData_773302, "RankExpression.RankName",
      newJString(RankExpressionRankName))
  add(formData_773302, "RankExpression.RankExpression",
      newJString(RankExpressionRankExpression))
  add(query_773301, "Action", newJString(Action))
  add(query_773301, "Version", newJString(Version))
  result = call_773300.call(nil, query_773301, nil, formData_773302, nil)

var postDefineRankExpression* = Call_PostDefineRankExpression_773284(
    name: "postDefineRankExpression", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineRankExpression",
    validator: validate_PostDefineRankExpression_773285, base: "/",
    url: url_PostDefineRankExpression_773286, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDefineRankExpression_773266 = ref object of OpenApiRestCall_772597
proc url_GetDefineRankExpression_773268(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDefineRankExpression_773267(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures a <code>RankExpression</code> for the search domain. Used to create new rank expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. You can configure a maximum of 50 rank expressions.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   RankExpression.RankExpression: JString
  ##                                : A named expression that can be evaluated at search time and used for ranking or thresholding in a search query. 
  ## <p>The expression to evaluate for ranking or thresholding while processing a search request. The <code>RankExpression</code> syntax is based on JavaScript expressions and supports:</p> <ul> <li>Integer, floating point, hex and octal literals</li> <li>Shortcut evaluation of logical operators such that an expression <code>a || b</code> evaluates to the value <code>a</code>, if <code>a</code> is true, without evaluating <code>b</code> at all</li> <li>JavaScript order of precedence for operators</li> <li>Arithmetic operators: <code>+ - * / %</code> </li> <li>Boolean operators (including the ternary operator)</li> <li>Bitwise operators</li> <li>Comparison operators</li> <li>Common mathematic functions: <code>abs ceil erf exp floor lgamma ln log2 log10 max min sqrt pow</code> </li> <li>Trigonometric library functions: <code>acosh acos asinh asin atanh atan cosh cos sinh sin tanh tan</code> </li> <li>Random generation of a number between 0 and 1: <code>rand</code> </li> <li>Current time in epoch: <code>time</code> </li> <li>The <code>min max</code> functions that operate on a variable argument list</li> </ul> <p>Intermediate results are calculated as double precision floating point values. The final return value of a <code>RankExpression</code> is automatically converted from floating point to a 32-bit unsigned integer by rounding to the nearest integer, with a natural floor of 0 and a ceiling of max(uint32_t), 4294967295. Mathematical errors such as dividing by 0 will fail during evaluation and return a value of 0.</p> <p>The source data for a <code>RankExpression</code> can be the name of an <code>IndexField</code> of type uint, another <code>RankExpression</code> or the reserved name <i>text_relevance</i>. The text_relevance source is defined to return an integer from 0 to 1000 (inclusive) to indicate how relevant a document is to the search request, taking into account repetition of search terms in the document and proximity of search terms to each other in each matching <code>IndexField</code> in the document.</p> <p>For more information about using rank expressions to customize ranking, see the Amazon CloudSearch Developer Guide.</p>
  ##   RankExpression.RankName: JString
  ##                          : A named expression that can be evaluated at search time and used for ranking or thresholding in a search query. 
  ## The name of a rank expression. Rank expression names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773269 = query.getOrDefault("Action")
  valid_773269 = validateParameter(valid_773269, JString, required = true,
                                 default = newJString("DefineRankExpression"))
  if valid_773269 != nil:
    section.add "Action", valid_773269
  var valid_773270 = query.getOrDefault("RankExpression.RankExpression")
  valid_773270 = validateParameter(valid_773270, JString, required = false,
                                 default = nil)
  if valid_773270 != nil:
    section.add "RankExpression.RankExpression", valid_773270
  var valid_773271 = query.getOrDefault("RankExpression.RankName")
  valid_773271 = validateParameter(valid_773271, JString, required = false,
                                 default = nil)
  if valid_773271 != nil:
    section.add "RankExpression.RankName", valid_773271
  var valid_773272 = query.getOrDefault("DomainName")
  valid_773272 = validateParameter(valid_773272, JString, required = true,
                                 default = nil)
  if valid_773272 != nil:
    section.add "DomainName", valid_773272
  var valid_773273 = query.getOrDefault("Version")
  valid_773273 = validateParameter(valid_773273, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_773273 != nil:
    section.add "Version", valid_773273
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773274 = header.getOrDefault("X-Amz-Date")
  valid_773274 = validateParameter(valid_773274, JString, required = false,
                                 default = nil)
  if valid_773274 != nil:
    section.add "X-Amz-Date", valid_773274
  var valid_773275 = header.getOrDefault("X-Amz-Security-Token")
  valid_773275 = validateParameter(valid_773275, JString, required = false,
                                 default = nil)
  if valid_773275 != nil:
    section.add "X-Amz-Security-Token", valid_773275
  var valid_773276 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773276 = validateParameter(valid_773276, JString, required = false,
                                 default = nil)
  if valid_773276 != nil:
    section.add "X-Amz-Content-Sha256", valid_773276
  var valid_773277 = header.getOrDefault("X-Amz-Algorithm")
  valid_773277 = validateParameter(valid_773277, JString, required = false,
                                 default = nil)
  if valid_773277 != nil:
    section.add "X-Amz-Algorithm", valid_773277
  var valid_773278 = header.getOrDefault("X-Amz-Signature")
  valid_773278 = validateParameter(valid_773278, JString, required = false,
                                 default = nil)
  if valid_773278 != nil:
    section.add "X-Amz-Signature", valid_773278
  var valid_773279 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773279 = validateParameter(valid_773279, JString, required = false,
                                 default = nil)
  if valid_773279 != nil:
    section.add "X-Amz-SignedHeaders", valid_773279
  var valid_773280 = header.getOrDefault("X-Amz-Credential")
  valid_773280 = validateParameter(valid_773280, JString, required = false,
                                 default = nil)
  if valid_773280 != nil:
    section.add "X-Amz-Credential", valid_773280
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773281: Call_GetDefineRankExpression_773266; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a <code>RankExpression</code> for the search domain. Used to create new rank expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. You can configure a maximum of 50 rank expressions.
  ## 
  let valid = call_773281.validator(path, query, header, formData, body)
  let scheme = call_773281.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773281.url(scheme.get, call_773281.host, call_773281.base,
                         call_773281.route, valid.getOrDefault("path"))
  result = hook(call_773281, url, valid)

proc call*(call_773282: Call_GetDefineRankExpression_773266; DomainName: string;
          Action: string = "DefineRankExpression";
          RankExpressionRankExpression: string = "";
          RankExpressionRankName: string = ""; Version: string = "2011-02-01"): Recallable =
  ## getDefineRankExpression
  ## Configures a <code>RankExpression</code> for the search domain. Used to create new rank expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. You can configure a maximum of 50 rank expressions.
  ##   Action: string (required)
  ##   RankExpressionRankExpression: string
  ##                               : A named expression that can be evaluated at search time and used for ranking or thresholding in a search query. 
  ## <p>The expression to evaluate for ranking or thresholding while processing a search request. The <code>RankExpression</code> syntax is based on JavaScript expressions and supports:</p> <ul> <li>Integer, floating point, hex and octal literals</li> <li>Shortcut evaluation of logical operators such that an expression <code>a || b</code> evaluates to the value <code>a</code>, if <code>a</code> is true, without evaluating <code>b</code> at all</li> <li>JavaScript order of precedence for operators</li> <li>Arithmetic operators: <code>+ - * / %</code> </li> <li>Boolean operators (including the ternary operator)</li> <li>Bitwise operators</li> <li>Comparison operators</li> <li>Common mathematic functions: <code>abs ceil erf exp floor lgamma ln log2 log10 max min sqrt pow</code> </li> <li>Trigonometric library functions: <code>acosh acos asinh asin atanh atan cosh cos sinh sin tanh tan</code> </li> <li>Random generation of a number between 0 and 1: <code>rand</code> </li> <li>Current time in epoch: <code>time</code> </li> <li>The <code>min max</code> functions that operate on a variable argument list</li> </ul> <p>Intermediate results are calculated as double precision floating point values. The final return value of a <code>RankExpression</code> is automatically converted from floating point to a 32-bit unsigned integer by rounding to the nearest integer, with a natural floor of 0 and a ceiling of max(uint32_t), 4294967295. Mathematical errors such as dividing by 0 will fail during evaluation and return a value of 0.</p> <p>The source data for a <code>RankExpression</code> can be the name of an <code>IndexField</code> of type uint, another <code>RankExpression</code> or the reserved name <i>text_relevance</i>. The text_relevance source is defined to return an integer from 0 to 1000 (inclusive) to indicate how relevant a document is to the search request, taking into account repetition of search terms in the document and proximity of search terms to each other in each matching <code>IndexField</code> in the document.</p> <p>For more information about using rank expressions to customize ranking, see the Amazon CloudSearch Developer Guide.</p>
  ##   RankExpressionRankName: string
  ##                         : A named expression that can be evaluated at search time and used for ranking or thresholding in a search query. 
  ## The name of a rank expression. Rank expression names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_773283 = newJObject()
  add(query_773283, "Action", newJString(Action))
  add(query_773283, "RankExpression.RankExpression",
      newJString(RankExpressionRankExpression))
  add(query_773283, "RankExpression.RankName", newJString(RankExpressionRankName))
  add(query_773283, "DomainName", newJString(DomainName))
  add(query_773283, "Version", newJString(Version))
  result = call_773282.call(nil, query_773283, nil, nil, nil)

var getDefineRankExpression* = Call_GetDefineRankExpression_773266(
    name: "getDefineRankExpression", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineRankExpression",
    validator: validate_GetDefineRankExpression_773267, base: "/",
    url: url_GetDefineRankExpression_773268, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDomain_773319 = ref object of OpenApiRestCall_772597
proc url_PostDeleteDomain_773321(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteDomain_773320(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Permanently deletes a search domain and all of its data.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773322 = query.getOrDefault("Action")
  valid_773322 = validateParameter(valid_773322, JString, required = true,
                                 default = newJString("DeleteDomain"))
  if valid_773322 != nil:
    section.add "Action", valid_773322
  var valid_773323 = query.getOrDefault("Version")
  valid_773323 = validateParameter(valid_773323, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_773323 != nil:
    section.add "Version", valid_773323
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773324 = header.getOrDefault("X-Amz-Date")
  valid_773324 = validateParameter(valid_773324, JString, required = false,
                                 default = nil)
  if valid_773324 != nil:
    section.add "X-Amz-Date", valid_773324
  var valid_773325 = header.getOrDefault("X-Amz-Security-Token")
  valid_773325 = validateParameter(valid_773325, JString, required = false,
                                 default = nil)
  if valid_773325 != nil:
    section.add "X-Amz-Security-Token", valid_773325
  var valid_773326 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773326 = validateParameter(valid_773326, JString, required = false,
                                 default = nil)
  if valid_773326 != nil:
    section.add "X-Amz-Content-Sha256", valid_773326
  var valid_773327 = header.getOrDefault("X-Amz-Algorithm")
  valid_773327 = validateParameter(valid_773327, JString, required = false,
                                 default = nil)
  if valid_773327 != nil:
    section.add "X-Amz-Algorithm", valid_773327
  var valid_773328 = header.getOrDefault("X-Amz-Signature")
  valid_773328 = validateParameter(valid_773328, JString, required = false,
                                 default = nil)
  if valid_773328 != nil:
    section.add "X-Amz-Signature", valid_773328
  var valid_773329 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773329 = validateParameter(valid_773329, JString, required = false,
                                 default = nil)
  if valid_773329 != nil:
    section.add "X-Amz-SignedHeaders", valid_773329
  var valid_773330 = header.getOrDefault("X-Amz-Credential")
  valid_773330 = validateParameter(valid_773330, JString, required = false,
                                 default = nil)
  if valid_773330 != nil:
    section.add "X-Amz-Credential", valid_773330
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_773331 = formData.getOrDefault("DomainName")
  valid_773331 = validateParameter(valid_773331, JString, required = true,
                                 default = nil)
  if valid_773331 != nil:
    section.add "DomainName", valid_773331
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773332: Call_PostDeleteDomain_773319; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently deletes a search domain and all of its data.
  ## 
  let valid = call_773332.validator(path, query, header, formData, body)
  let scheme = call_773332.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773332.url(scheme.get, call_773332.host, call_773332.base,
                         call_773332.route, valid.getOrDefault("path"))
  result = hook(call_773332, url, valid)

proc call*(call_773333: Call_PostDeleteDomain_773319; DomainName: string;
          Action: string = "DeleteDomain"; Version: string = "2011-02-01"): Recallable =
  ## postDeleteDomain
  ## Permanently deletes a search domain and all of its data.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773334 = newJObject()
  var formData_773335 = newJObject()
  add(formData_773335, "DomainName", newJString(DomainName))
  add(query_773334, "Action", newJString(Action))
  add(query_773334, "Version", newJString(Version))
  result = call_773333.call(nil, query_773334, nil, formData_773335, nil)

var postDeleteDomain* = Call_PostDeleteDomain_773319(name: "postDeleteDomain",
    meth: HttpMethod.HttpPost, host: "cloudsearch.amazonaws.com",
    route: "/#Action=DeleteDomain", validator: validate_PostDeleteDomain_773320,
    base: "/", url: url_PostDeleteDomain_773321,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDomain_773303 = ref object of OpenApiRestCall_772597
proc url_GetDeleteDomain_773305(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteDomain_773304(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Permanently deletes a search domain and all of its data.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773306 = query.getOrDefault("Action")
  valid_773306 = validateParameter(valid_773306, JString, required = true,
                                 default = newJString("DeleteDomain"))
  if valid_773306 != nil:
    section.add "Action", valid_773306
  var valid_773307 = query.getOrDefault("DomainName")
  valid_773307 = validateParameter(valid_773307, JString, required = true,
                                 default = nil)
  if valid_773307 != nil:
    section.add "DomainName", valid_773307
  var valid_773308 = query.getOrDefault("Version")
  valid_773308 = validateParameter(valid_773308, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_773308 != nil:
    section.add "Version", valid_773308
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773309 = header.getOrDefault("X-Amz-Date")
  valid_773309 = validateParameter(valid_773309, JString, required = false,
                                 default = nil)
  if valid_773309 != nil:
    section.add "X-Amz-Date", valid_773309
  var valid_773310 = header.getOrDefault("X-Amz-Security-Token")
  valid_773310 = validateParameter(valid_773310, JString, required = false,
                                 default = nil)
  if valid_773310 != nil:
    section.add "X-Amz-Security-Token", valid_773310
  var valid_773311 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773311 = validateParameter(valid_773311, JString, required = false,
                                 default = nil)
  if valid_773311 != nil:
    section.add "X-Amz-Content-Sha256", valid_773311
  var valid_773312 = header.getOrDefault("X-Amz-Algorithm")
  valid_773312 = validateParameter(valid_773312, JString, required = false,
                                 default = nil)
  if valid_773312 != nil:
    section.add "X-Amz-Algorithm", valid_773312
  var valid_773313 = header.getOrDefault("X-Amz-Signature")
  valid_773313 = validateParameter(valid_773313, JString, required = false,
                                 default = nil)
  if valid_773313 != nil:
    section.add "X-Amz-Signature", valid_773313
  var valid_773314 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773314 = validateParameter(valid_773314, JString, required = false,
                                 default = nil)
  if valid_773314 != nil:
    section.add "X-Amz-SignedHeaders", valid_773314
  var valid_773315 = header.getOrDefault("X-Amz-Credential")
  valid_773315 = validateParameter(valid_773315, JString, required = false,
                                 default = nil)
  if valid_773315 != nil:
    section.add "X-Amz-Credential", valid_773315
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773316: Call_GetDeleteDomain_773303; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently deletes a search domain and all of its data.
  ## 
  let valid = call_773316.validator(path, query, header, formData, body)
  let scheme = call_773316.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773316.url(scheme.get, call_773316.host, call_773316.base,
                         call_773316.route, valid.getOrDefault("path"))
  result = hook(call_773316, url, valid)

proc call*(call_773317: Call_GetDeleteDomain_773303; DomainName: string;
          Action: string = "DeleteDomain"; Version: string = "2011-02-01"): Recallable =
  ## getDeleteDomain
  ## Permanently deletes a search domain and all of its data.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_773318 = newJObject()
  add(query_773318, "Action", newJString(Action))
  add(query_773318, "DomainName", newJString(DomainName))
  add(query_773318, "Version", newJString(Version))
  result = call_773317.call(nil, query_773318, nil, nil, nil)

var getDeleteDomain* = Call_GetDeleteDomain_773303(name: "getDeleteDomain",
    meth: HttpMethod.HttpGet, host: "cloudsearch.amazonaws.com",
    route: "/#Action=DeleteDomain", validator: validate_GetDeleteDomain_773304,
    base: "/", url: url_GetDeleteDomain_773305, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteIndexField_773353 = ref object of OpenApiRestCall_772597
proc url_PostDeleteIndexField_773355(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteIndexField_773354(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes an <code>IndexField</code> from the search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773356 = query.getOrDefault("Action")
  valid_773356 = validateParameter(valid_773356, JString, required = true,
                                 default = newJString("DeleteIndexField"))
  if valid_773356 != nil:
    section.add "Action", valid_773356
  var valid_773357 = query.getOrDefault("Version")
  valid_773357 = validateParameter(valid_773357, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_773357 != nil:
    section.add "Version", valid_773357
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773358 = header.getOrDefault("X-Amz-Date")
  valid_773358 = validateParameter(valid_773358, JString, required = false,
                                 default = nil)
  if valid_773358 != nil:
    section.add "X-Amz-Date", valid_773358
  var valid_773359 = header.getOrDefault("X-Amz-Security-Token")
  valid_773359 = validateParameter(valid_773359, JString, required = false,
                                 default = nil)
  if valid_773359 != nil:
    section.add "X-Amz-Security-Token", valid_773359
  var valid_773360 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773360 = validateParameter(valid_773360, JString, required = false,
                                 default = nil)
  if valid_773360 != nil:
    section.add "X-Amz-Content-Sha256", valid_773360
  var valid_773361 = header.getOrDefault("X-Amz-Algorithm")
  valid_773361 = validateParameter(valid_773361, JString, required = false,
                                 default = nil)
  if valid_773361 != nil:
    section.add "X-Amz-Algorithm", valid_773361
  var valid_773362 = header.getOrDefault("X-Amz-Signature")
  valid_773362 = validateParameter(valid_773362, JString, required = false,
                                 default = nil)
  if valid_773362 != nil:
    section.add "X-Amz-Signature", valid_773362
  var valid_773363 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773363 = validateParameter(valid_773363, JString, required = false,
                                 default = nil)
  if valid_773363 != nil:
    section.add "X-Amz-SignedHeaders", valid_773363
  var valid_773364 = header.getOrDefault("X-Amz-Credential")
  valid_773364 = validateParameter(valid_773364, JString, required = false,
                                 default = nil)
  if valid_773364 != nil:
    section.add "X-Amz-Credential", valid_773364
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   IndexFieldName: JString (required)
  ##                 : A string that represents the name of an index field. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_773365 = formData.getOrDefault("DomainName")
  valid_773365 = validateParameter(valid_773365, JString, required = true,
                                 default = nil)
  if valid_773365 != nil:
    section.add "DomainName", valid_773365
  var valid_773366 = formData.getOrDefault("IndexFieldName")
  valid_773366 = validateParameter(valid_773366, JString, required = true,
                                 default = nil)
  if valid_773366 != nil:
    section.add "IndexFieldName", valid_773366
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773367: Call_PostDeleteIndexField_773353; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes an <code>IndexField</code> from the search domain.
  ## 
  let valid = call_773367.validator(path, query, header, formData, body)
  let scheme = call_773367.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773367.url(scheme.get, call_773367.host, call_773367.base,
                         call_773367.route, valid.getOrDefault("path"))
  result = hook(call_773367, url, valid)

proc call*(call_773368: Call_PostDeleteIndexField_773353; DomainName: string;
          IndexFieldName: string; Action: string = "DeleteIndexField";
          Version: string = "2011-02-01"): Recallable =
  ## postDeleteIndexField
  ## Removes an <code>IndexField</code> from the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   IndexFieldName: string (required)
  ##                 : A string that represents the name of an index field. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773369 = newJObject()
  var formData_773370 = newJObject()
  add(formData_773370, "DomainName", newJString(DomainName))
  add(formData_773370, "IndexFieldName", newJString(IndexFieldName))
  add(query_773369, "Action", newJString(Action))
  add(query_773369, "Version", newJString(Version))
  result = call_773368.call(nil, query_773369, nil, formData_773370, nil)

var postDeleteIndexField* = Call_PostDeleteIndexField_773353(
    name: "postDeleteIndexField", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteIndexField",
    validator: validate_PostDeleteIndexField_773354, base: "/",
    url: url_PostDeleteIndexField_773355, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteIndexField_773336 = ref object of OpenApiRestCall_772597
proc url_GetDeleteIndexField_773338(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteIndexField_773337(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Removes an <code>IndexField</code> from the search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   IndexFieldName: JString (required)
  ##                 : A string that represents the name of an index field. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `IndexFieldName` field"
  var valid_773339 = query.getOrDefault("IndexFieldName")
  valid_773339 = validateParameter(valid_773339, JString, required = true,
                                 default = nil)
  if valid_773339 != nil:
    section.add "IndexFieldName", valid_773339
  var valid_773340 = query.getOrDefault("Action")
  valid_773340 = validateParameter(valid_773340, JString, required = true,
                                 default = newJString("DeleteIndexField"))
  if valid_773340 != nil:
    section.add "Action", valid_773340
  var valid_773341 = query.getOrDefault("DomainName")
  valid_773341 = validateParameter(valid_773341, JString, required = true,
                                 default = nil)
  if valid_773341 != nil:
    section.add "DomainName", valid_773341
  var valid_773342 = query.getOrDefault("Version")
  valid_773342 = validateParameter(valid_773342, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_773342 != nil:
    section.add "Version", valid_773342
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773343 = header.getOrDefault("X-Amz-Date")
  valid_773343 = validateParameter(valid_773343, JString, required = false,
                                 default = nil)
  if valid_773343 != nil:
    section.add "X-Amz-Date", valid_773343
  var valid_773344 = header.getOrDefault("X-Amz-Security-Token")
  valid_773344 = validateParameter(valid_773344, JString, required = false,
                                 default = nil)
  if valid_773344 != nil:
    section.add "X-Amz-Security-Token", valid_773344
  var valid_773345 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773345 = validateParameter(valid_773345, JString, required = false,
                                 default = nil)
  if valid_773345 != nil:
    section.add "X-Amz-Content-Sha256", valid_773345
  var valid_773346 = header.getOrDefault("X-Amz-Algorithm")
  valid_773346 = validateParameter(valid_773346, JString, required = false,
                                 default = nil)
  if valid_773346 != nil:
    section.add "X-Amz-Algorithm", valid_773346
  var valid_773347 = header.getOrDefault("X-Amz-Signature")
  valid_773347 = validateParameter(valid_773347, JString, required = false,
                                 default = nil)
  if valid_773347 != nil:
    section.add "X-Amz-Signature", valid_773347
  var valid_773348 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773348 = validateParameter(valid_773348, JString, required = false,
                                 default = nil)
  if valid_773348 != nil:
    section.add "X-Amz-SignedHeaders", valid_773348
  var valid_773349 = header.getOrDefault("X-Amz-Credential")
  valid_773349 = validateParameter(valid_773349, JString, required = false,
                                 default = nil)
  if valid_773349 != nil:
    section.add "X-Amz-Credential", valid_773349
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773350: Call_GetDeleteIndexField_773336; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes an <code>IndexField</code> from the search domain.
  ## 
  let valid = call_773350.validator(path, query, header, formData, body)
  let scheme = call_773350.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773350.url(scheme.get, call_773350.host, call_773350.base,
                         call_773350.route, valid.getOrDefault("path"))
  result = hook(call_773350, url, valid)

proc call*(call_773351: Call_GetDeleteIndexField_773336; IndexFieldName: string;
          DomainName: string; Action: string = "DeleteIndexField";
          Version: string = "2011-02-01"): Recallable =
  ## getDeleteIndexField
  ## Removes an <code>IndexField</code> from the search domain.
  ##   IndexFieldName: string (required)
  ##                 : A string that represents the name of an index field. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_773352 = newJObject()
  add(query_773352, "IndexFieldName", newJString(IndexFieldName))
  add(query_773352, "Action", newJString(Action))
  add(query_773352, "DomainName", newJString(DomainName))
  add(query_773352, "Version", newJString(Version))
  result = call_773351.call(nil, query_773352, nil, nil, nil)

var getDeleteIndexField* = Call_GetDeleteIndexField_773336(
    name: "getDeleteIndexField", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteIndexField",
    validator: validate_GetDeleteIndexField_773337, base: "/",
    url: url_GetDeleteIndexField_773338, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteRankExpression_773388 = ref object of OpenApiRestCall_772597
proc url_PostDeleteRankExpression_773390(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteRankExpression_773389(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes a <code>RankExpression</code> from the search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773391 = query.getOrDefault("Action")
  valid_773391 = validateParameter(valid_773391, JString, required = true,
                                 default = newJString("DeleteRankExpression"))
  if valid_773391 != nil:
    section.add "Action", valid_773391
  var valid_773392 = query.getOrDefault("Version")
  valid_773392 = validateParameter(valid_773392, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_773392 != nil:
    section.add "Version", valid_773392
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773393 = header.getOrDefault("X-Amz-Date")
  valid_773393 = validateParameter(valid_773393, JString, required = false,
                                 default = nil)
  if valid_773393 != nil:
    section.add "X-Amz-Date", valid_773393
  var valid_773394 = header.getOrDefault("X-Amz-Security-Token")
  valid_773394 = validateParameter(valid_773394, JString, required = false,
                                 default = nil)
  if valid_773394 != nil:
    section.add "X-Amz-Security-Token", valid_773394
  var valid_773395 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773395 = validateParameter(valid_773395, JString, required = false,
                                 default = nil)
  if valid_773395 != nil:
    section.add "X-Amz-Content-Sha256", valid_773395
  var valid_773396 = header.getOrDefault("X-Amz-Algorithm")
  valid_773396 = validateParameter(valid_773396, JString, required = false,
                                 default = nil)
  if valid_773396 != nil:
    section.add "X-Amz-Algorithm", valid_773396
  var valid_773397 = header.getOrDefault("X-Amz-Signature")
  valid_773397 = validateParameter(valid_773397, JString, required = false,
                                 default = nil)
  if valid_773397 != nil:
    section.add "X-Amz-Signature", valid_773397
  var valid_773398 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773398 = validateParameter(valid_773398, JString, required = false,
                                 default = nil)
  if valid_773398 != nil:
    section.add "X-Amz-SignedHeaders", valid_773398
  var valid_773399 = header.getOrDefault("X-Amz-Credential")
  valid_773399 = validateParameter(valid_773399, JString, required = false,
                                 default = nil)
  if valid_773399 != nil:
    section.add "X-Amz-Credential", valid_773399
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   RankName: JString (required)
  ##           : A string that represents the name of an index field. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_773400 = formData.getOrDefault("DomainName")
  valid_773400 = validateParameter(valid_773400, JString, required = true,
                                 default = nil)
  if valid_773400 != nil:
    section.add "DomainName", valid_773400
  var valid_773401 = formData.getOrDefault("RankName")
  valid_773401 = validateParameter(valid_773401, JString, required = true,
                                 default = nil)
  if valid_773401 != nil:
    section.add "RankName", valid_773401
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773402: Call_PostDeleteRankExpression_773388; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a <code>RankExpression</code> from the search domain.
  ## 
  let valid = call_773402.validator(path, query, header, formData, body)
  let scheme = call_773402.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773402.url(scheme.get, call_773402.host, call_773402.base,
                         call_773402.route, valid.getOrDefault("path"))
  result = hook(call_773402, url, valid)

proc call*(call_773403: Call_PostDeleteRankExpression_773388; DomainName: string;
          RankName: string; Action: string = "DeleteRankExpression";
          Version: string = "2011-02-01"): Recallable =
  ## postDeleteRankExpression
  ## Removes a <code>RankExpression</code> from the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   RankName: string (required)
  ##           : A string that represents the name of an index field. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   Version: string (required)
  var query_773404 = newJObject()
  var formData_773405 = newJObject()
  add(formData_773405, "DomainName", newJString(DomainName))
  add(query_773404, "Action", newJString(Action))
  add(formData_773405, "RankName", newJString(RankName))
  add(query_773404, "Version", newJString(Version))
  result = call_773403.call(nil, query_773404, nil, formData_773405, nil)

var postDeleteRankExpression* = Call_PostDeleteRankExpression_773388(
    name: "postDeleteRankExpression", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteRankExpression",
    validator: validate_PostDeleteRankExpression_773389, base: "/",
    url: url_PostDeleteRankExpression_773390, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteRankExpression_773371 = ref object of OpenApiRestCall_772597
proc url_GetDeleteRankExpression_773373(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteRankExpression_773372(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes a <code>RankExpression</code> from the search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   RankName: JString (required)
  ##           : A string that represents the name of an index field. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `RankName` field"
  var valid_773374 = query.getOrDefault("RankName")
  valid_773374 = validateParameter(valid_773374, JString, required = true,
                                 default = nil)
  if valid_773374 != nil:
    section.add "RankName", valid_773374
  var valid_773375 = query.getOrDefault("Action")
  valid_773375 = validateParameter(valid_773375, JString, required = true,
                                 default = newJString("DeleteRankExpression"))
  if valid_773375 != nil:
    section.add "Action", valid_773375
  var valid_773376 = query.getOrDefault("DomainName")
  valid_773376 = validateParameter(valid_773376, JString, required = true,
                                 default = nil)
  if valid_773376 != nil:
    section.add "DomainName", valid_773376
  var valid_773377 = query.getOrDefault("Version")
  valid_773377 = validateParameter(valid_773377, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_773377 != nil:
    section.add "Version", valid_773377
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773378 = header.getOrDefault("X-Amz-Date")
  valid_773378 = validateParameter(valid_773378, JString, required = false,
                                 default = nil)
  if valid_773378 != nil:
    section.add "X-Amz-Date", valid_773378
  var valid_773379 = header.getOrDefault("X-Amz-Security-Token")
  valid_773379 = validateParameter(valid_773379, JString, required = false,
                                 default = nil)
  if valid_773379 != nil:
    section.add "X-Amz-Security-Token", valid_773379
  var valid_773380 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773380 = validateParameter(valid_773380, JString, required = false,
                                 default = nil)
  if valid_773380 != nil:
    section.add "X-Amz-Content-Sha256", valid_773380
  var valid_773381 = header.getOrDefault("X-Amz-Algorithm")
  valid_773381 = validateParameter(valid_773381, JString, required = false,
                                 default = nil)
  if valid_773381 != nil:
    section.add "X-Amz-Algorithm", valid_773381
  var valid_773382 = header.getOrDefault("X-Amz-Signature")
  valid_773382 = validateParameter(valid_773382, JString, required = false,
                                 default = nil)
  if valid_773382 != nil:
    section.add "X-Amz-Signature", valid_773382
  var valid_773383 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773383 = validateParameter(valid_773383, JString, required = false,
                                 default = nil)
  if valid_773383 != nil:
    section.add "X-Amz-SignedHeaders", valid_773383
  var valid_773384 = header.getOrDefault("X-Amz-Credential")
  valid_773384 = validateParameter(valid_773384, JString, required = false,
                                 default = nil)
  if valid_773384 != nil:
    section.add "X-Amz-Credential", valid_773384
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773385: Call_GetDeleteRankExpression_773371; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a <code>RankExpression</code> from the search domain.
  ## 
  let valid = call_773385.validator(path, query, header, formData, body)
  let scheme = call_773385.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773385.url(scheme.get, call_773385.host, call_773385.base,
                         call_773385.route, valid.getOrDefault("path"))
  result = hook(call_773385, url, valid)

proc call*(call_773386: Call_GetDeleteRankExpression_773371; RankName: string;
          DomainName: string; Action: string = "DeleteRankExpression";
          Version: string = "2011-02-01"): Recallable =
  ## getDeleteRankExpression
  ## Removes a <code>RankExpression</code> from the search domain.
  ##   RankName: string (required)
  ##           : A string that represents the name of an index field. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_773387 = newJObject()
  add(query_773387, "RankName", newJString(RankName))
  add(query_773387, "Action", newJString(Action))
  add(query_773387, "DomainName", newJString(DomainName))
  add(query_773387, "Version", newJString(Version))
  result = call_773386.call(nil, query_773387, nil, nil, nil)

var getDeleteRankExpression* = Call_GetDeleteRankExpression_773371(
    name: "getDeleteRankExpression", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteRankExpression",
    validator: validate_GetDeleteRankExpression_773372, base: "/",
    url: url_GetDeleteRankExpression_773373, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAvailabilityOptions_773422 = ref object of OpenApiRestCall_772597
proc url_PostDescribeAvailabilityOptions_773424(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeAvailabilityOptions_773423(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773425 = query.getOrDefault("Action")
  valid_773425 = validateParameter(valid_773425, JString, required = true, default = newJString(
      "DescribeAvailabilityOptions"))
  if valid_773425 != nil:
    section.add "Action", valid_773425
  var valid_773426 = query.getOrDefault("Version")
  valid_773426 = validateParameter(valid_773426, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_773426 != nil:
    section.add "Version", valid_773426
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773427 = header.getOrDefault("X-Amz-Date")
  valid_773427 = validateParameter(valid_773427, JString, required = false,
                                 default = nil)
  if valid_773427 != nil:
    section.add "X-Amz-Date", valid_773427
  var valid_773428 = header.getOrDefault("X-Amz-Security-Token")
  valid_773428 = validateParameter(valid_773428, JString, required = false,
                                 default = nil)
  if valid_773428 != nil:
    section.add "X-Amz-Security-Token", valid_773428
  var valid_773429 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773429 = validateParameter(valid_773429, JString, required = false,
                                 default = nil)
  if valid_773429 != nil:
    section.add "X-Amz-Content-Sha256", valid_773429
  var valid_773430 = header.getOrDefault("X-Amz-Algorithm")
  valid_773430 = validateParameter(valid_773430, JString, required = false,
                                 default = nil)
  if valid_773430 != nil:
    section.add "X-Amz-Algorithm", valid_773430
  var valid_773431 = header.getOrDefault("X-Amz-Signature")
  valid_773431 = validateParameter(valid_773431, JString, required = false,
                                 default = nil)
  if valid_773431 != nil:
    section.add "X-Amz-Signature", valid_773431
  var valid_773432 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773432 = validateParameter(valid_773432, JString, required = false,
                                 default = nil)
  if valid_773432 != nil:
    section.add "X-Amz-SignedHeaders", valid_773432
  var valid_773433 = header.getOrDefault("X-Amz-Credential")
  valid_773433 = validateParameter(valid_773433, JString, required = false,
                                 default = nil)
  if valid_773433 != nil:
    section.add "X-Amz-Credential", valid_773433
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_773434 = formData.getOrDefault("DomainName")
  valid_773434 = validateParameter(valid_773434, JString, required = true,
                                 default = nil)
  if valid_773434 != nil:
    section.add "DomainName", valid_773434
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773435: Call_PostDescribeAvailabilityOptions_773422;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_773435.validator(path, query, header, formData, body)
  let scheme = call_773435.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773435.url(scheme.get, call_773435.host, call_773435.base,
                         call_773435.route, valid.getOrDefault("path"))
  result = hook(call_773435, url, valid)

proc call*(call_773436: Call_PostDescribeAvailabilityOptions_773422;
          DomainName: string; Action: string = "DescribeAvailabilityOptions";
          Version: string = "2011-02-01"): Recallable =
  ## postDescribeAvailabilityOptions
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773437 = newJObject()
  var formData_773438 = newJObject()
  add(formData_773438, "DomainName", newJString(DomainName))
  add(query_773437, "Action", newJString(Action))
  add(query_773437, "Version", newJString(Version))
  result = call_773436.call(nil, query_773437, nil, formData_773438, nil)

var postDescribeAvailabilityOptions* = Call_PostDescribeAvailabilityOptions_773422(
    name: "postDescribeAvailabilityOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeAvailabilityOptions",
    validator: validate_PostDescribeAvailabilityOptions_773423, base: "/",
    url: url_PostDescribeAvailabilityOptions_773424,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAvailabilityOptions_773406 = ref object of OpenApiRestCall_772597
proc url_GetDescribeAvailabilityOptions_773408(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeAvailabilityOptions_773407(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773409 = query.getOrDefault("Action")
  valid_773409 = validateParameter(valid_773409, JString, required = true, default = newJString(
      "DescribeAvailabilityOptions"))
  if valid_773409 != nil:
    section.add "Action", valid_773409
  var valid_773410 = query.getOrDefault("DomainName")
  valid_773410 = validateParameter(valid_773410, JString, required = true,
                                 default = nil)
  if valid_773410 != nil:
    section.add "DomainName", valid_773410
  var valid_773411 = query.getOrDefault("Version")
  valid_773411 = validateParameter(valid_773411, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_773411 != nil:
    section.add "Version", valid_773411
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773412 = header.getOrDefault("X-Amz-Date")
  valid_773412 = validateParameter(valid_773412, JString, required = false,
                                 default = nil)
  if valid_773412 != nil:
    section.add "X-Amz-Date", valid_773412
  var valid_773413 = header.getOrDefault("X-Amz-Security-Token")
  valid_773413 = validateParameter(valid_773413, JString, required = false,
                                 default = nil)
  if valid_773413 != nil:
    section.add "X-Amz-Security-Token", valid_773413
  var valid_773414 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773414 = validateParameter(valid_773414, JString, required = false,
                                 default = nil)
  if valid_773414 != nil:
    section.add "X-Amz-Content-Sha256", valid_773414
  var valid_773415 = header.getOrDefault("X-Amz-Algorithm")
  valid_773415 = validateParameter(valid_773415, JString, required = false,
                                 default = nil)
  if valid_773415 != nil:
    section.add "X-Amz-Algorithm", valid_773415
  var valid_773416 = header.getOrDefault("X-Amz-Signature")
  valid_773416 = validateParameter(valid_773416, JString, required = false,
                                 default = nil)
  if valid_773416 != nil:
    section.add "X-Amz-Signature", valid_773416
  var valid_773417 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773417 = validateParameter(valid_773417, JString, required = false,
                                 default = nil)
  if valid_773417 != nil:
    section.add "X-Amz-SignedHeaders", valid_773417
  var valid_773418 = header.getOrDefault("X-Amz-Credential")
  valid_773418 = validateParameter(valid_773418, JString, required = false,
                                 default = nil)
  if valid_773418 != nil:
    section.add "X-Amz-Credential", valid_773418
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773419: Call_GetDescribeAvailabilityOptions_773406; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_773419.validator(path, query, header, formData, body)
  let scheme = call_773419.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773419.url(scheme.get, call_773419.host, call_773419.base,
                         call_773419.route, valid.getOrDefault("path"))
  result = hook(call_773419, url, valid)

proc call*(call_773420: Call_GetDescribeAvailabilityOptions_773406;
          DomainName: string; Action: string = "DescribeAvailabilityOptions";
          Version: string = "2011-02-01"): Recallable =
  ## getDescribeAvailabilityOptions
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_773421 = newJObject()
  add(query_773421, "Action", newJString(Action))
  add(query_773421, "DomainName", newJString(DomainName))
  add(query_773421, "Version", newJString(Version))
  result = call_773420.call(nil, query_773421, nil, nil, nil)

var getDescribeAvailabilityOptions* = Call_GetDescribeAvailabilityOptions_773406(
    name: "getDescribeAvailabilityOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeAvailabilityOptions",
    validator: validate_GetDescribeAvailabilityOptions_773407, base: "/",
    url: url_GetDescribeAvailabilityOptions_773408,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDefaultSearchField_773455 = ref object of OpenApiRestCall_772597
proc url_PostDescribeDefaultSearchField_773457(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDefaultSearchField_773456(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the default search field configured for the search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773458 = query.getOrDefault("Action")
  valid_773458 = validateParameter(valid_773458, JString, required = true, default = newJString(
      "DescribeDefaultSearchField"))
  if valid_773458 != nil:
    section.add "Action", valid_773458
  var valid_773459 = query.getOrDefault("Version")
  valid_773459 = validateParameter(valid_773459, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_773459 != nil:
    section.add "Version", valid_773459
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773460 = header.getOrDefault("X-Amz-Date")
  valid_773460 = validateParameter(valid_773460, JString, required = false,
                                 default = nil)
  if valid_773460 != nil:
    section.add "X-Amz-Date", valid_773460
  var valid_773461 = header.getOrDefault("X-Amz-Security-Token")
  valid_773461 = validateParameter(valid_773461, JString, required = false,
                                 default = nil)
  if valid_773461 != nil:
    section.add "X-Amz-Security-Token", valid_773461
  var valid_773462 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773462 = validateParameter(valid_773462, JString, required = false,
                                 default = nil)
  if valid_773462 != nil:
    section.add "X-Amz-Content-Sha256", valid_773462
  var valid_773463 = header.getOrDefault("X-Amz-Algorithm")
  valid_773463 = validateParameter(valid_773463, JString, required = false,
                                 default = nil)
  if valid_773463 != nil:
    section.add "X-Amz-Algorithm", valid_773463
  var valid_773464 = header.getOrDefault("X-Amz-Signature")
  valid_773464 = validateParameter(valid_773464, JString, required = false,
                                 default = nil)
  if valid_773464 != nil:
    section.add "X-Amz-Signature", valid_773464
  var valid_773465 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773465 = validateParameter(valid_773465, JString, required = false,
                                 default = nil)
  if valid_773465 != nil:
    section.add "X-Amz-SignedHeaders", valid_773465
  var valid_773466 = header.getOrDefault("X-Amz-Credential")
  valid_773466 = validateParameter(valid_773466, JString, required = false,
                                 default = nil)
  if valid_773466 != nil:
    section.add "X-Amz-Credential", valid_773466
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_773467 = formData.getOrDefault("DomainName")
  valid_773467 = validateParameter(valid_773467, JString, required = true,
                                 default = nil)
  if valid_773467 != nil:
    section.add "DomainName", valid_773467
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773468: Call_PostDescribeDefaultSearchField_773455; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the default search field configured for the search domain.
  ## 
  let valid = call_773468.validator(path, query, header, formData, body)
  let scheme = call_773468.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773468.url(scheme.get, call_773468.host, call_773468.base,
                         call_773468.route, valid.getOrDefault("path"))
  result = hook(call_773468, url, valid)

proc call*(call_773469: Call_PostDescribeDefaultSearchField_773455;
          DomainName: string; Action: string = "DescribeDefaultSearchField";
          Version: string = "2011-02-01"): Recallable =
  ## postDescribeDefaultSearchField
  ## Gets the default search field configured for the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773470 = newJObject()
  var formData_773471 = newJObject()
  add(formData_773471, "DomainName", newJString(DomainName))
  add(query_773470, "Action", newJString(Action))
  add(query_773470, "Version", newJString(Version))
  result = call_773469.call(nil, query_773470, nil, formData_773471, nil)

var postDescribeDefaultSearchField* = Call_PostDescribeDefaultSearchField_773455(
    name: "postDescribeDefaultSearchField", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeDefaultSearchField",
    validator: validate_PostDescribeDefaultSearchField_773456, base: "/",
    url: url_PostDescribeDefaultSearchField_773457,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDefaultSearchField_773439 = ref object of OpenApiRestCall_772597
proc url_GetDescribeDefaultSearchField_773441(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDefaultSearchField_773440(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the default search field configured for the search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773442 = query.getOrDefault("Action")
  valid_773442 = validateParameter(valid_773442, JString, required = true, default = newJString(
      "DescribeDefaultSearchField"))
  if valid_773442 != nil:
    section.add "Action", valid_773442
  var valid_773443 = query.getOrDefault("DomainName")
  valid_773443 = validateParameter(valid_773443, JString, required = true,
                                 default = nil)
  if valid_773443 != nil:
    section.add "DomainName", valid_773443
  var valid_773444 = query.getOrDefault("Version")
  valid_773444 = validateParameter(valid_773444, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_773444 != nil:
    section.add "Version", valid_773444
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773445 = header.getOrDefault("X-Amz-Date")
  valid_773445 = validateParameter(valid_773445, JString, required = false,
                                 default = nil)
  if valid_773445 != nil:
    section.add "X-Amz-Date", valid_773445
  var valid_773446 = header.getOrDefault("X-Amz-Security-Token")
  valid_773446 = validateParameter(valid_773446, JString, required = false,
                                 default = nil)
  if valid_773446 != nil:
    section.add "X-Amz-Security-Token", valid_773446
  var valid_773447 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773447 = validateParameter(valid_773447, JString, required = false,
                                 default = nil)
  if valid_773447 != nil:
    section.add "X-Amz-Content-Sha256", valid_773447
  var valid_773448 = header.getOrDefault("X-Amz-Algorithm")
  valid_773448 = validateParameter(valid_773448, JString, required = false,
                                 default = nil)
  if valid_773448 != nil:
    section.add "X-Amz-Algorithm", valid_773448
  var valid_773449 = header.getOrDefault("X-Amz-Signature")
  valid_773449 = validateParameter(valid_773449, JString, required = false,
                                 default = nil)
  if valid_773449 != nil:
    section.add "X-Amz-Signature", valid_773449
  var valid_773450 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773450 = validateParameter(valid_773450, JString, required = false,
                                 default = nil)
  if valid_773450 != nil:
    section.add "X-Amz-SignedHeaders", valid_773450
  var valid_773451 = header.getOrDefault("X-Amz-Credential")
  valid_773451 = validateParameter(valid_773451, JString, required = false,
                                 default = nil)
  if valid_773451 != nil:
    section.add "X-Amz-Credential", valid_773451
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773452: Call_GetDescribeDefaultSearchField_773439; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the default search field configured for the search domain.
  ## 
  let valid = call_773452.validator(path, query, header, formData, body)
  let scheme = call_773452.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773452.url(scheme.get, call_773452.host, call_773452.base,
                         call_773452.route, valid.getOrDefault("path"))
  result = hook(call_773452, url, valid)

proc call*(call_773453: Call_GetDescribeDefaultSearchField_773439;
          DomainName: string; Action: string = "DescribeDefaultSearchField";
          Version: string = "2011-02-01"): Recallable =
  ## getDescribeDefaultSearchField
  ## Gets the default search field configured for the search domain.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_773454 = newJObject()
  add(query_773454, "Action", newJString(Action))
  add(query_773454, "DomainName", newJString(DomainName))
  add(query_773454, "Version", newJString(Version))
  result = call_773453.call(nil, query_773454, nil, nil, nil)

var getDescribeDefaultSearchField* = Call_GetDescribeDefaultSearchField_773439(
    name: "getDescribeDefaultSearchField", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeDefaultSearchField",
    validator: validate_GetDescribeDefaultSearchField_773440, base: "/",
    url: url_GetDescribeDefaultSearchField_773441,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDomains_773488 = ref object of OpenApiRestCall_772597
proc url_PostDescribeDomains_773490(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDomains_773489(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773491 = query.getOrDefault("Action")
  valid_773491 = validateParameter(valid_773491, JString, required = true,
                                 default = newJString("DescribeDomains"))
  if valid_773491 != nil:
    section.add "Action", valid_773491
  var valid_773492 = query.getOrDefault("Version")
  valid_773492 = validateParameter(valid_773492, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_773492 != nil:
    section.add "Version", valid_773492
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773493 = header.getOrDefault("X-Amz-Date")
  valid_773493 = validateParameter(valid_773493, JString, required = false,
                                 default = nil)
  if valid_773493 != nil:
    section.add "X-Amz-Date", valid_773493
  var valid_773494 = header.getOrDefault("X-Amz-Security-Token")
  valid_773494 = validateParameter(valid_773494, JString, required = false,
                                 default = nil)
  if valid_773494 != nil:
    section.add "X-Amz-Security-Token", valid_773494
  var valid_773495 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773495 = validateParameter(valid_773495, JString, required = false,
                                 default = nil)
  if valid_773495 != nil:
    section.add "X-Amz-Content-Sha256", valid_773495
  var valid_773496 = header.getOrDefault("X-Amz-Algorithm")
  valid_773496 = validateParameter(valid_773496, JString, required = false,
                                 default = nil)
  if valid_773496 != nil:
    section.add "X-Amz-Algorithm", valid_773496
  var valid_773497 = header.getOrDefault("X-Amz-Signature")
  valid_773497 = validateParameter(valid_773497, JString, required = false,
                                 default = nil)
  if valid_773497 != nil:
    section.add "X-Amz-Signature", valid_773497
  var valid_773498 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773498 = validateParameter(valid_773498, JString, required = false,
                                 default = nil)
  if valid_773498 != nil:
    section.add "X-Amz-SignedHeaders", valid_773498
  var valid_773499 = header.getOrDefault("X-Amz-Credential")
  valid_773499 = validateParameter(valid_773499, JString, required = false,
                                 default = nil)
  if valid_773499 != nil:
    section.add "X-Amz-Credential", valid_773499
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainNames: JArray
  ##              : A list of domain names.
  section = newJObject()
  var valid_773500 = formData.getOrDefault("DomainNames")
  valid_773500 = validateParameter(valid_773500, JArray, required = false,
                                 default = nil)
  if valid_773500 != nil:
    section.add "DomainNames", valid_773500
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773501: Call_PostDescribeDomains_773488; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default.
  ## 
  let valid = call_773501.validator(path, query, header, formData, body)
  let scheme = call_773501.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773501.url(scheme.get, call_773501.host, call_773501.base,
                         call_773501.route, valid.getOrDefault("path"))
  result = hook(call_773501, url, valid)

proc call*(call_773502: Call_PostDescribeDomains_773488;
          DomainNames: JsonNode = nil; Action: string = "DescribeDomains";
          Version: string = "2011-02-01"): Recallable =
  ## postDescribeDomains
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default.
  ##   DomainNames: JArray
  ##              : A list of domain names.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773503 = newJObject()
  var formData_773504 = newJObject()
  if DomainNames != nil:
    formData_773504.add "DomainNames", DomainNames
  add(query_773503, "Action", newJString(Action))
  add(query_773503, "Version", newJString(Version))
  result = call_773502.call(nil, query_773503, nil, formData_773504, nil)

var postDescribeDomains* = Call_PostDescribeDomains_773488(
    name: "postDescribeDomains", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeDomains",
    validator: validate_PostDescribeDomains_773489, base: "/",
    url: url_PostDescribeDomains_773490, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDomains_773472 = ref object of OpenApiRestCall_772597
proc url_GetDescribeDomains_773474(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDomains_773473(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainNames: JArray
  ##              : A list of domain names.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  var valid_773475 = query.getOrDefault("DomainNames")
  valid_773475 = validateParameter(valid_773475, JArray, required = false,
                                 default = nil)
  if valid_773475 != nil:
    section.add "DomainNames", valid_773475
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773476 = query.getOrDefault("Action")
  valid_773476 = validateParameter(valid_773476, JString, required = true,
                                 default = newJString("DescribeDomains"))
  if valid_773476 != nil:
    section.add "Action", valid_773476
  var valid_773477 = query.getOrDefault("Version")
  valid_773477 = validateParameter(valid_773477, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_773477 != nil:
    section.add "Version", valid_773477
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773478 = header.getOrDefault("X-Amz-Date")
  valid_773478 = validateParameter(valid_773478, JString, required = false,
                                 default = nil)
  if valid_773478 != nil:
    section.add "X-Amz-Date", valid_773478
  var valid_773479 = header.getOrDefault("X-Amz-Security-Token")
  valid_773479 = validateParameter(valid_773479, JString, required = false,
                                 default = nil)
  if valid_773479 != nil:
    section.add "X-Amz-Security-Token", valid_773479
  var valid_773480 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773480 = validateParameter(valid_773480, JString, required = false,
                                 default = nil)
  if valid_773480 != nil:
    section.add "X-Amz-Content-Sha256", valid_773480
  var valid_773481 = header.getOrDefault("X-Amz-Algorithm")
  valid_773481 = validateParameter(valid_773481, JString, required = false,
                                 default = nil)
  if valid_773481 != nil:
    section.add "X-Amz-Algorithm", valid_773481
  var valid_773482 = header.getOrDefault("X-Amz-Signature")
  valid_773482 = validateParameter(valid_773482, JString, required = false,
                                 default = nil)
  if valid_773482 != nil:
    section.add "X-Amz-Signature", valid_773482
  var valid_773483 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773483 = validateParameter(valid_773483, JString, required = false,
                                 default = nil)
  if valid_773483 != nil:
    section.add "X-Amz-SignedHeaders", valid_773483
  var valid_773484 = header.getOrDefault("X-Amz-Credential")
  valid_773484 = validateParameter(valid_773484, JString, required = false,
                                 default = nil)
  if valid_773484 != nil:
    section.add "X-Amz-Credential", valid_773484
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773485: Call_GetDescribeDomains_773472; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default.
  ## 
  let valid = call_773485.validator(path, query, header, formData, body)
  let scheme = call_773485.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773485.url(scheme.get, call_773485.host, call_773485.base,
                         call_773485.route, valid.getOrDefault("path"))
  result = hook(call_773485, url, valid)

proc call*(call_773486: Call_GetDescribeDomains_773472;
          DomainNames: JsonNode = nil; Action: string = "DescribeDomains";
          Version: string = "2011-02-01"): Recallable =
  ## getDescribeDomains
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default.
  ##   DomainNames: JArray
  ##              : A list of domain names.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773487 = newJObject()
  if DomainNames != nil:
    query_773487.add "DomainNames", DomainNames
  add(query_773487, "Action", newJString(Action))
  add(query_773487, "Version", newJString(Version))
  result = call_773486.call(nil, query_773487, nil, nil, nil)

var getDescribeDomains* = Call_GetDescribeDomains_773472(
    name: "getDescribeDomains", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeDomains",
    validator: validate_GetDescribeDomains_773473, base: "/",
    url: url_GetDescribeDomains_773474, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeIndexFields_773522 = ref object of OpenApiRestCall_772597
proc url_PostDescribeIndexFields_773524(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeIndexFields_773523(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. Shows all fields by default.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773525 = query.getOrDefault("Action")
  valid_773525 = validateParameter(valid_773525, JString, required = true,
                                 default = newJString("DescribeIndexFields"))
  if valid_773525 != nil:
    section.add "Action", valid_773525
  var valid_773526 = query.getOrDefault("Version")
  valid_773526 = validateParameter(valid_773526, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_773526 != nil:
    section.add "Version", valid_773526
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773527 = header.getOrDefault("X-Amz-Date")
  valid_773527 = validateParameter(valid_773527, JString, required = false,
                                 default = nil)
  if valid_773527 != nil:
    section.add "X-Amz-Date", valid_773527
  var valid_773528 = header.getOrDefault("X-Amz-Security-Token")
  valid_773528 = validateParameter(valid_773528, JString, required = false,
                                 default = nil)
  if valid_773528 != nil:
    section.add "X-Amz-Security-Token", valid_773528
  var valid_773529 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773529 = validateParameter(valid_773529, JString, required = false,
                                 default = nil)
  if valid_773529 != nil:
    section.add "X-Amz-Content-Sha256", valid_773529
  var valid_773530 = header.getOrDefault("X-Amz-Algorithm")
  valid_773530 = validateParameter(valid_773530, JString, required = false,
                                 default = nil)
  if valid_773530 != nil:
    section.add "X-Amz-Algorithm", valid_773530
  var valid_773531 = header.getOrDefault("X-Amz-Signature")
  valid_773531 = validateParameter(valid_773531, JString, required = false,
                                 default = nil)
  if valid_773531 != nil:
    section.add "X-Amz-Signature", valid_773531
  var valid_773532 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773532 = validateParameter(valid_773532, JString, required = false,
                                 default = nil)
  if valid_773532 != nil:
    section.add "X-Amz-SignedHeaders", valid_773532
  var valid_773533 = header.getOrDefault("X-Amz-Credential")
  valid_773533 = validateParameter(valid_773533, JString, required = false,
                                 default = nil)
  if valid_773533 != nil:
    section.add "X-Amz-Credential", valid_773533
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   FieldNames: JArray
  ##             : Limits the <code>DescribeIndexFields</code> response to the specified fields.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_773534 = formData.getOrDefault("DomainName")
  valid_773534 = validateParameter(valid_773534, JString, required = true,
                                 default = nil)
  if valid_773534 != nil:
    section.add "DomainName", valid_773534
  var valid_773535 = formData.getOrDefault("FieldNames")
  valid_773535 = validateParameter(valid_773535, JArray, required = false,
                                 default = nil)
  if valid_773535 != nil:
    section.add "FieldNames", valid_773535
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773536: Call_PostDescribeIndexFields_773522; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. Shows all fields by default.
  ## 
  let valid = call_773536.validator(path, query, header, formData, body)
  let scheme = call_773536.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773536.url(scheme.get, call_773536.host, call_773536.base,
                         call_773536.route, valid.getOrDefault("path"))
  result = hook(call_773536, url, valid)

proc call*(call_773537: Call_PostDescribeIndexFields_773522; DomainName: string;
          Action: string = "DescribeIndexFields"; FieldNames: JsonNode = nil;
          Version: string = "2011-02-01"): Recallable =
  ## postDescribeIndexFields
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. Shows all fields by default.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   FieldNames: JArray
  ##             : Limits the <code>DescribeIndexFields</code> response to the specified fields.
  ##   Version: string (required)
  var query_773538 = newJObject()
  var formData_773539 = newJObject()
  add(formData_773539, "DomainName", newJString(DomainName))
  add(query_773538, "Action", newJString(Action))
  if FieldNames != nil:
    formData_773539.add "FieldNames", FieldNames
  add(query_773538, "Version", newJString(Version))
  result = call_773537.call(nil, query_773538, nil, formData_773539, nil)

var postDescribeIndexFields* = Call_PostDescribeIndexFields_773522(
    name: "postDescribeIndexFields", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeIndexFields",
    validator: validate_PostDescribeIndexFields_773523, base: "/",
    url: url_PostDescribeIndexFields_773524, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeIndexFields_773505 = ref object of OpenApiRestCall_772597
proc url_GetDescribeIndexFields_773507(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeIndexFields_773506(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. Shows all fields by default.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   FieldNames: JArray
  ##             : Limits the <code>DescribeIndexFields</code> response to the specified fields.
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: JString (required)
  section = newJObject()
  var valid_773508 = query.getOrDefault("FieldNames")
  valid_773508 = validateParameter(valid_773508, JArray, required = false,
                                 default = nil)
  if valid_773508 != nil:
    section.add "FieldNames", valid_773508
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773509 = query.getOrDefault("Action")
  valid_773509 = validateParameter(valid_773509, JString, required = true,
                                 default = newJString("DescribeIndexFields"))
  if valid_773509 != nil:
    section.add "Action", valid_773509
  var valid_773510 = query.getOrDefault("DomainName")
  valid_773510 = validateParameter(valid_773510, JString, required = true,
                                 default = nil)
  if valid_773510 != nil:
    section.add "DomainName", valid_773510
  var valid_773511 = query.getOrDefault("Version")
  valid_773511 = validateParameter(valid_773511, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_773511 != nil:
    section.add "Version", valid_773511
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773512 = header.getOrDefault("X-Amz-Date")
  valid_773512 = validateParameter(valid_773512, JString, required = false,
                                 default = nil)
  if valid_773512 != nil:
    section.add "X-Amz-Date", valid_773512
  var valid_773513 = header.getOrDefault("X-Amz-Security-Token")
  valid_773513 = validateParameter(valid_773513, JString, required = false,
                                 default = nil)
  if valid_773513 != nil:
    section.add "X-Amz-Security-Token", valid_773513
  var valid_773514 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773514 = validateParameter(valid_773514, JString, required = false,
                                 default = nil)
  if valid_773514 != nil:
    section.add "X-Amz-Content-Sha256", valid_773514
  var valid_773515 = header.getOrDefault("X-Amz-Algorithm")
  valid_773515 = validateParameter(valid_773515, JString, required = false,
                                 default = nil)
  if valid_773515 != nil:
    section.add "X-Amz-Algorithm", valid_773515
  var valid_773516 = header.getOrDefault("X-Amz-Signature")
  valid_773516 = validateParameter(valid_773516, JString, required = false,
                                 default = nil)
  if valid_773516 != nil:
    section.add "X-Amz-Signature", valid_773516
  var valid_773517 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773517 = validateParameter(valid_773517, JString, required = false,
                                 default = nil)
  if valid_773517 != nil:
    section.add "X-Amz-SignedHeaders", valid_773517
  var valid_773518 = header.getOrDefault("X-Amz-Credential")
  valid_773518 = validateParameter(valid_773518, JString, required = false,
                                 default = nil)
  if valid_773518 != nil:
    section.add "X-Amz-Credential", valid_773518
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773519: Call_GetDescribeIndexFields_773505; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. Shows all fields by default.
  ## 
  let valid = call_773519.validator(path, query, header, formData, body)
  let scheme = call_773519.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773519.url(scheme.get, call_773519.host, call_773519.base,
                         call_773519.route, valid.getOrDefault("path"))
  result = hook(call_773519, url, valid)

proc call*(call_773520: Call_GetDescribeIndexFields_773505; DomainName: string;
          FieldNames: JsonNode = nil; Action: string = "DescribeIndexFields";
          Version: string = "2011-02-01"): Recallable =
  ## getDescribeIndexFields
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. Shows all fields by default.
  ##   FieldNames: JArray
  ##             : Limits the <code>DescribeIndexFields</code> response to the specified fields.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_773521 = newJObject()
  if FieldNames != nil:
    query_773521.add "FieldNames", FieldNames
  add(query_773521, "Action", newJString(Action))
  add(query_773521, "DomainName", newJString(DomainName))
  add(query_773521, "Version", newJString(Version))
  result = call_773520.call(nil, query_773521, nil, nil, nil)

var getDescribeIndexFields* = Call_GetDescribeIndexFields_773505(
    name: "getDescribeIndexFields", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeIndexFields",
    validator: validate_GetDescribeIndexFields_773506, base: "/",
    url: url_GetDescribeIndexFields_773507, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeRankExpressions_773557 = ref object of OpenApiRestCall_772597
proc url_PostDescribeRankExpressions_773559(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeRankExpressions_773558(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the rank expressions configured for the search domain. Can be limited to specific rank expressions by name. Shows all rank expressions by default. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773560 = query.getOrDefault("Action")
  valid_773560 = validateParameter(valid_773560, JString, required = true, default = newJString(
      "DescribeRankExpressions"))
  if valid_773560 != nil:
    section.add "Action", valid_773560
  var valid_773561 = query.getOrDefault("Version")
  valid_773561 = validateParameter(valid_773561, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_773561 != nil:
    section.add "Version", valid_773561
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773562 = header.getOrDefault("X-Amz-Date")
  valid_773562 = validateParameter(valid_773562, JString, required = false,
                                 default = nil)
  if valid_773562 != nil:
    section.add "X-Amz-Date", valid_773562
  var valid_773563 = header.getOrDefault("X-Amz-Security-Token")
  valid_773563 = validateParameter(valid_773563, JString, required = false,
                                 default = nil)
  if valid_773563 != nil:
    section.add "X-Amz-Security-Token", valid_773563
  var valid_773564 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773564 = validateParameter(valid_773564, JString, required = false,
                                 default = nil)
  if valid_773564 != nil:
    section.add "X-Amz-Content-Sha256", valid_773564
  var valid_773565 = header.getOrDefault("X-Amz-Algorithm")
  valid_773565 = validateParameter(valid_773565, JString, required = false,
                                 default = nil)
  if valid_773565 != nil:
    section.add "X-Amz-Algorithm", valid_773565
  var valid_773566 = header.getOrDefault("X-Amz-Signature")
  valid_773566 = validateParameter(valid_773566, JString, required = false,
                                 default = nil)
  if valid_773566 != nil:
    section.add "X-Amz-Signature", valid_773566
  var valid_773567 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773567 = validateParameter(valid_773567, JString, required = false,
                                 default = nil)
  if valid_773567 != nil:
    section.add "X-Amz-SignedHeaders", valid_773567
  var valid_773568 = header.getOrDefault("X-Amz-Credential")
  valid_773568 = validateParameter(valid_773568, JString, required = false,
                                 default = nil)
  if valid_773568 != nil:
    section.add "X-Amz-Credential", valid_773568
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   RankNames: JArray
  ##            : Limits the <code>DescribeRankExpressions</code> response to the specified fields.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_773569 = formData.getOrDefault("DomainName")
  valid_773569 = validateParameter(valid_773569, JString, required = true,
                                 default = nil)
  if valid_773569 != nil:
    section.add "DomainName", valid_773569
  var valid_773570 = formData.getOrDefault("RankNames")
  valid_773570 = validateParameter(valid_773570, JArray, required = false,
                                 default = nil)
  if valid_773570 != nil:
    section.add "RankNames", valid_773570
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773571: Call_PostDescribeRankExpressions_773557; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the rank expressions configured for the search domain. Can be limited to specific rank expressions by name. Shows all rank expressions by default. 
  ## 
  let valid = call_773571.validator(path, query, header, formData, body)
  let scheme = call_773571.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773571.url(scheme.get, call_773571.host, call_773571.base,
                         call_773571.route, valid.getOrDefault("path"))
  result = hook(call_773571, url, valid)

proc call*(call_773572: Call_PostDescribeRankExpressions_773557;
          DomainName: string; Action: string = "DescribeRankExpressions";
          RankNames: JsonNode = nil; Version: string = "2011-02-01"): Recallable =
  ## postDescribeRankExpressions
  ## Gets the rank expressions configured for the search domain. Can be limited to specific rank expressions by name. Shows all rank expressions by default. 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   RankNames: JArray
  ##            : Limits the <code>DescribeRankExpressions</code> response to the specified fields.
  ##   Version: string (required)
  var query_773573 = newJObject()
  var formData_773574 = newJObject()
  add(formData_773574, "DomainName", newJString(DomainName))
  add(query_773573, "Action", newJString(Action))
  if RankNames != nil:
    formData_773574.add "RankNames", RankNames
  add(query_773573, "Version", newJString(Version))
  result = call_773572.call(nil, query_773573, nil, formData_773574, nil)

var postDescribeRankExpressions* = Call_PostDescribeRankExpressions_773557(
    name: "postDescribeRankExpressions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeRankExpressions",
    validator: validate_PostDescribeRankExpressions_773558, base: "/",
    url: url_PostDescribeRankExpressions_773559,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeRankExpressions_773540 = ref object of OpenApiRestCall_772597
proc url_GetDescribeRankExpressions_773542(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeRankExpressions_773541(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the rank expressions configured for the search domain. Can be limited to specific rank expressions by name. Shows all rank expressions by default. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   RankNames: JArray
  ##            : Limits the <code>DescribeRankExpressions</code> response to the specified fields.
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: JString (required)
  section = newJObject()
  var valid_773543 = query.getOrDefault("RankNames")
  valid_773543 = validateParameter(valid_773543, JArray, required = false,
                                 default = nil)
  if valid_773543 != nil:
    section.add "RankNames", valid_773543
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773544 = query.getOrDefault("Action")
  valid_773544 = validateParameter(valid_773544, JString, required = true, default = newJString(
      "DescribeRankExpressions"))
  if valid_773544 != nil:
    section.add "Action", valid_773544
  var valid_773545 = query.getOrDefault("DomainName")
  valid_773545 = validateParameter(valid_773545, JString, required = true,
                                 default = nil)
  if valid_773545 != nil:
    section.add "DomainName", valid_773545
  var valid_773546 = query.getOrDefault("Version")
  valid_773546 = validateParameter(valid_773546, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_773546 != nil:
    section.add "Version", valid_773546
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773547 = header.getOrDefault("X-Amz-Date")
  valid_773547 = validateParameter(valid_773547, JString, required = false,
                                 default = nil)
  if valid_773547 != nil:
    section.add "X-Amz-Date", valid_773547
  var valid_773548 = header.getOrDefault("X-Amz-Security-Token")
  valid_773548 = validateParameter(valid_773548, JString, required = false,
                                 default = nil)
  if valid_773548 != nil:
    section.add "X-Amz-Security-Token", valid_773548
  var valid_773549 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773549 = validateParameter(valid_773549, JString, required = false,
                                 default = nil)
  if valid_773549 != nil:
    section.add "X-Amz-Content-Sha256", valid_773549
  var valid_773550 = header.getOrDefault("X-Amz-Algorithm")
  valid_773550 = validateParameter(valid_773550, JString, required = false,
                                 default = nil)
  if valid_773550 != nil:
    section.add "X-Amz-Algorithm", valid_773550
  var valid_773551 = header.getOrDefault("X-Amz-Signature")
  valid_773551 = validateParameter(valid_773551, JString, required = false,
                                 default = nil)
  if valid_773551 != nil:
    section.add "X-Amz-Signature", valid_773551
  var valid_773552 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773552 = validateParameter(valid_773552, JString, required = false,
                                 default = nil)
  if valid_773552 != nil:
    section.add "X-Amz-SignedHeaders", valid_773552
  var valid_773553 = header.getOrDefault("X-Amz-Credential")
  valid_773553 = validateParameter(valid_773553, JString, required = false,
                                 default = nil)
  if valid_773553 != nil:
    section.add "X-Amz-Credential", valid_773553
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773554: Call_GetDescribeRankExpressions_773540; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the rank expressions configured for the search domain. Can be limited to specific rank expressions by name. Shows all rank expressions by default. 
  ## 
  let valid = call_773554.validator(path, query, header, formData, body)
  let scheme = call_773554.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773554.url(scheme.get, call_773554.host, call_773554.base,
                         call_773554.route, valid.getOrDefault("path"))
  result = hook(call_773554, url, valid)

proc call*(call_773555: Call_GetDescribeRankExpressions_773540; DomainName: string;
          RankNames: JsonNode = nil; Action: string = "DescribeRankExpressions";
          Version: string = "2011-02-01"): Recallable =
  ## getDescribeRankExpressions
  ## Gets the rank expressions configured for the search domain. Can be limited to specific rank expressions by name. Shows all rank expressions by default. 
  ##   RankNames: JArray
  ##            : Limits the <code>DescribeRankExpressions</code> response to the specified fields.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_773556 = newJObject()
  if RankNames != nil:
    query_773556.add "RankNames", RankNames
  add(query_773556, "Action", newJString(Action))
  add(query_773556, "DomainName", newJString(DomainName))
  add(query_773556, "Version", newJString(Version))
  result = call_773555.call(nil, query_773556, nil, nil, nil)

var getDescribeRankExpressions* = Call_GetDescribeRankExpressions_773540(
    name: "getDescribeRankExpressions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeRankExpressions",
    validator: validate_GetDescribeRankExpressions_773541, base: "/",
    url: url_GetDescribeRankExpressions_773542,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeServiceAccessPolicies_773591 = ref object of OpenApiRestCall_772597
proc url_PostDescribeServiceAccessPolicies_773593(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeServiceAccessPolicies_773592(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about the resource-based policies that control access to the domain's document and search services.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773594 = query.getOrDefault("Action")
  valid_773594 = validateParameter(valid_773594, JString, required = true, default = newJString(
      "DescribeServiceAccessPolicies"))
  if valid_773594 != nil:
    section.add "Action", valid_773594
  var valid_773595 = query.getOrDefault("Version")
  valid_773595 = validateParameter(valid_773595, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_773595 != nil:
    section.add "Version", valid_773595
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773596 = header.getOrDefault("X-Amz-Date")
  valid_773596 = validateParameter(valid_773596, JString, required = false,
                                 default = nil)
  if valid_773596 != nil:
    section.add "X-Amz-Date", valid_773596
  var valid_773597 = header.getOrDefault("X-Amz-Security-Token")
  valid_773597 = validateParameter(valid_773597, JString, required = false,
                                 default = nil)
  if valid_773597 != nil:
    section.add "X-Amz-Security-Token", valid_773597
  var valid_773598 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773598 = validateParameter(valid_773598, JString, required = false,
                                 default = nil)
  if valid_773598 != nil:
    section.add "X-Amz-Content-Sha256", valid_773598
  var valid_773599 = header.getOrDefault("X-Amz-Algorithm")
  valid_773599 = validateParameter(valid_773599, JString, required = false,
                                 default = nil)
  if valid_773599 != nil:
    section.add "X-Amz-Algorithm", valid_773599
  var valid_773600 = header.getOrDefault("X-Amz-Signature")
  valid_773600 = validateParameter(valid_773600, JString, required = false,
                                 default = nil)
  if valid_773600 != nil:
    section.add "X-Amz-Signature", valid_773600
  var valid_773601 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773601 = validateParameter(valid_773601, JString, required = false,
                                 default = nil)
  if valid_773601 != nil:
    section.add "X-Amz-SignedHeaders", valid_773601
  var valid_773602 = header.getOrDefault("X-Amz-Credential")
  valid_773602 = validateParameter(valid_773602, JString, required = false,
                                 default = nil)
  if valid_773602 != nil:
    section.add "X-Amz-Credential", valid_773602
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_773603 = formData.getOrDefault("DomainName")
  valid_773603 = validateParameter(valid_773603, JString, required = true,
                                 default = nil)
  if valid_773603 != nil:
    section.add "DomainName", valid_773603
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773604: Call_PostDescribeServiceAccessPolicies_773591;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets information about the resource-based policies that control access to the domain's document and search services.
  ## 
  let valid = call_773604.validator(path, query, header, formData, body)
  let scheme = call_773604.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773604.url(scheme.get, call_773604.host, call_773604.base,
                         call_773604.route, valid.getOrDefault("path"))
  result = hook(call_773604, url, valid)

proc call*(call_773605: Call_PostDescribeServiceAccessPolicies_773591;
          DomainName: string; Action: string = "DescribeServiceAccessPolicies";
          Version: string = "2011-02-01"): Recallable =
  ## postDescribeServiceAccessPolicies
  ## Gets information about the resource-based policies that control access to the domain's document and search services.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773606 = newJObject()
  var formData_773607 = newJObject()
  add(formData_773607, "DomainName", newJString(DomainName))
  add(query_773606, "Action", newJString(Action))
  add(query_773606, "Version", newJString(Version))
  result = call_773605.call(nil, query_773606, nil, formData_773607, nil)

var postDescribeServiceAccessPolicies* = Call_PostDescribeServiceAccessPolicies_773591(
    name: "postDescribeServiceAccessPolicies", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeServiceAccessPolicies",
    validator: validate_PostDescribeServiceAccessPolicies_773592, base: "/",
    url: url_PostDescribeServiceAccessPolicies_773593,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeServiceAccessPolicies_773575 = ref object of OpenApiRestCall_772597
proc url_GetDescribeServiceAccessPolicies_773577(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeServiceAccessPolicies_773576(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about the resource-based policies that control access to the domain's document and search services.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773578 = query.getOrDefault("Action")
  valid_773578 = validateParameter(valid_773578, JString, required = true, default = newJString(
      "DescribeServiceAccessPolicies"))
  if valid_773578 != nil:
    section.add "Action", valid_773578
  var valid_773579 = query.getOrDefault("DomainName")
  valid_773579 = validateParameter(valid_773579, JString, required = true,
                                 default = nil)
  if valid_773579 != nil:
    section.add "DomainName", valid_773579
  var valid_773580 = query.getOrDefault("Version")
  valid_773580 = validateParameter(valid_773580, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_773580 != nil:
    section.add "Version", valid_773580
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773581 = header.getOrDefault("X-Amz-Date")
  valid_773581 = validateParameter(valid_773581, JString, required = false,
                                 default = nil)
  if valid_773581 != nil:
    section.add "X-Amz-Date", valid_773581
  var valid_773582 = header.getOrDefault("X-Amz-Security-Token")
  valid_773582 = validateParameter(valid_773582, JString, required = false,
                                 default = nil)
  if valid_773582 != nil:
    section.add "X-Amz-Security-Token", valid_773582
  var valid_773583 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773583 = validateParameter(valid_773583, JString, required = false,
                                 default = nil)
  if valid_773583 != nil:
    section.add "X-Amz-Content-Sha256", valid_773583
  var valid_773584 = header.getOrDefault("X-Amz-Algorithm")
  valid_773584 = validateParameter(valid_773584, JString, required = false,
                                 default = nil)
  if valid_773584 != nil:
    section.add "X-Amz-Algorithm", valid_773584
  var valid_773585 = header.getOrDefault("X-Amz-Signature")
  valid_773585 = validateParameter(valid_773585, JString, required = false,
                                 default = nil)
  if valid_773585 != nil:
    section.add "X-Amz-Signature", valid_773585
  var valid_773586 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773586 = validateParameter(valid_773586, JString, required = false,
                                 default = nil)
  if valid_773586 != nil:
    section.add "X-Amz-SignedHeaders", valid_773586
  var valid_773587 = header.getOrDefault("X-Amz-Credential")
  valid_773587 = validateParameter(valid_773587, JString, required = false,
                                 default = nil)
  if valid_773587 != nil:
    section.add "X-Amz-Credential", valid_773587
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773588: Call_GetDescribeServiceAccessPolicies_773575;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets information about the resource-based policies that control access to the domain's document and search services.
  ## 
  let valid = call_773588.validator(path, query, header, formData, body)
  let scheme = call_773588.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773588.url(scheme.get, call_773588.host, call_773588.base,
                         call_773588.route, valid.getOrDefault("path"))
  result = hook(call_773588, url, valid)

proc call*(call_773589: Call_GetDescribeServiceAccessPolicies_773575;
          DomainName: string; Action: string = "DescribeServiceAccessPolicies";
          Version: string = "2011-02-01"): Recallable =
  ## getDescribeServiceAccessPolicies
  ## Gets information about the resource-based policies that control access to the domain's document and search services.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_773590 = newJObject()
  add(query_773590, "Action", newJString(Action))
  add(query_773590, "DomainName", newJString(DomainName))
  add(query_773590, "Version", newJString(Version))
  result = call_773589.call(nil, query_773590, nil, nil, nil)

var getDescribeServiceAccessPolicies* = Call_GetDescribeServiceAccessPolicies_773575(
    name: "getDescribeServiceAccessPolicies", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeServiceAccessPolicies",
    validator: validate_GetDescribeServiceAccessPolicies_773576, base: "/",
    url: url_GetDescribeServiceAccessPolicies_773577,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeStemmingOptions_773624 = ref object of OpenApiRestCall_772597
proc url_PostDescribeStemmingOptions_773626(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeStemmingOptions_773625(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the stemming dictionary configured for the search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773627 = query.getOrDefault("Action")
  valid_773627 = validateParameter(valid_773627, JString, required = true, default = newJString(
      "DescribeStemmingOptions"))
  if valid_773627 != nil:
    section.add "Action", valid_773627
  var valid_773628 = query.getOrDefault("Version")
  valid_773628 = validateParameter(valid_773628, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_773628 != nil:
    section.add "Version", valid_773628
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773629 = header.getOrDefault("X-Amz-Date")
  valid_773629 = validateParameter(valid_773629, JString, required = false,
                                 default = nil)
  if valid_773629 != nil:
    section.add "X-Amz-Date", valid_773629
  var valid_773630 = header.getOrDefault("X-Amz-Security-Token")
  valid_773630 = validateParameter(valid_773630, JString, required = false,
                                 default = nil)
  if valid_773630 != nil:
    section.add "X-Amz-Security-Token", valid_773630
  var valid_773631 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773631 = validateParameter(valid_773631, JString, required = false,
                                 default = nil)
  if valid_773631 != nil:
    section.add "X-Amz-Content-Sha256", valid_773631
  var valid_773632 = header.getOrDefault("X-Amz-Algorithm")
  valid_773632 = validateParameter(valid_773632, JString, required = false,
                                 default = nil)
  if valid_773632 != nil:
    section.add "X-Amz-Algorithm", valid_773632
  var valid_773633 = header.getOrDefault("X-Amz-Signature")
  valid_773633 = validateParameter(valid_773633, JString, required = false,
                                 default = nil)
  if valid_773633 != nil:
    section.add "X-Amz-Signature", valid_773633
  var valid_773634 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773634 = validateParameter(valid_773634, JString, required = false,
                                 default = nil)
  if valid_773634 != nil:
    section.add "X-Amz-SignedHeaders", valid_773634
  var valid_773635 = header.getOrDefault("X-Amz-Credential")
  valid_773635 = validateParameter(valid_773635, JString, required = false,
                                 default = nil)
  if valid_773635 != nil:
    section.add "X-Amz-Credential", valid_773635
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_773636 = formData.getOrDefault("DomainName")
  valid_773636 = validateParameter(valid_773636, JString, required = true,
                                 default = nil)
  if valid_773636 != nil:
    section.add "DomainName", valid_773636
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773637: Call_PostDescribeStemmingOptions_773624; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the stemming dictionary configured for the search domain.
  ## 
  let valid = call_773637.validator(path, query, header, formData, body)
  let scheme = call_773637.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773637.url(scheme.get, call_773637.host, call_773637.base,
                         call_773637.route, valid.getOrDefault("path"))
  result = hook(call_773637, url, valid)

proc call*(call_773638: Call_PostDescribeStemmingOptions_773624;
          DomainName: string; Action: string = "DescribeStemmingOptions";
          Version: string = "2011-02-01"): Recallable =
  ## postDescribeStemmingOptions
  ## Gets the stemming dictionary configured for the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773639 = newJObject()
  var formData_773640 = newJObject()
  add(formData_773640, "DomainName", newJString(DomainName))
  add(query_773639, "Action", newJString(Action))
  add(query_773639, "Version", newJString(Version))
  result = call_773638.call(nil, query_773639, nil, formData_773640, nil)

var postDescribeStemmingOptions* = Call_PostDescribeStemmingOptions_773624(
    name: "postDescribeStemmingOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeStemmingOptions",
    validator: validate_PostDescribeStemmingOptions_773625, base: "/",
    url: url_PostDescribeStemmingOptions_773626,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeStemmingOptions_773608 = ref object of OpenApiRestCall_772597
proc url_GetDescribeStemmingOptions_773610(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeStemmingOptions_773609(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the stemming dictionary configured for the search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773611 = query.getOrDefault("Action")
  valid_773611 = validateParameter(valid_773611, JString, required = true, default = newJString(
      "DescribeStemmingOptions"))
  if valid_773611 != nil:
    section.add "Action", valid_773611
  var valid_773612 = query.getOrDefault("DomainName")
  valid_773612 = validateParameter(valid_773612, JString, required = true,
                                 default = nil)
  if valid_773612 != nil:
    section.add "DomainName", valid_773612
  var valid_773613 = query.getOrDefault("Version")
  valid_773613 = validateParameter(valid_773613, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_773613 != nil:
    section.add "Version", valid_773613
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773614 = header.getOrDefault("X-Amz-Date")
  valid_773614 = validateParameter(valid_773614, JString, required = false,
                                 default = nil)
  if valid_773614 != nil:
    section.add "X-Amz-Date", valid_773614
  var valid_773615 = header.getOrDefault("X-Amz-Security-Token")
  valid_773615 = validateParameter(valid_773615, JString, required = false,
                                 default = nil)
  if valid_773615 != nil:
    section.add "X-Amz-Security-Token", valid_773615
  var valid_773616 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773616 = validateParameter(valid_773616, JString, required = false,
                                 default = nil)
  if valid_773616 != nil:
    section.add "X-Amz-Content-Sha256", valid_773616
  var valid_773617 = header.getOrDefault("X-Amz-Algorithm")
  valid_773617 = validateParameter(valid_773617, JString, required = false,
                                 default = nil)
  if valid_773617 != nil:
    section.add "X-Amz-Algorithm", valid_773617
  var valid_773618 = header.getOrDefault("X-Amz-Signature")
  valid_773618 = validateParameter(valid_773618, JString, required = false,
                                 default = nil)
  if valid_773618 != nil:
    section.add "X-Amz-Signature", valid_773618
  var valid_773619 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773619 = validateParameter(valid_773619, JString, required = false,
                                 default = nil)
  if valid_773619 != nil:
    section.add "X-Amz-SignedHeaders", valid_773619
  var valid_773620 = header.getOrDefault("X-Amz-Credential")
  valid_773620 = validateParameter(valid_773620, JString, required = false,
                                 default = nil)
  if valid_773620 != nil:
    section.add "X-Amz-Credential", valid_773620
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773621: Call_GetDescribeStemmingOptions_773608; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the stemming dictionary configured for the search domain.
  ## 
  let valid = call_773621.validator(path, query, header, formData, body)
  let scheme = call_773621.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773621.url(scheme.get, call_773621.host, call_773621.base,
                         call_773621.route, valid.getOrDefault("path"))
  result = hook(call_773621, url, valid)

proc call*(call_773622: Call_GetDescribeStemmingOptions_773608; DomainName: string;
          Action: string = "DescribeStemmingOptions"; Version: string = "2011-02-01"): Recallable =
  ## getDescribeStemmingOptions
  ## Gets the stemming dictionary configured for the search domain.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_773623 = newJObject()
  add(query_773623, "Action", newJString(Action))
  add(query_773623, "DomainName", newJString(DomainName))
  add(query_773623, "Version", newJString(Version))
  result = call_773622.call(nil, query_773623, nil, nil, nil)

var getDescribeStemmingOptions* = Call_GetDescribeStemmingOptions_773608(
    name: "getDescribeStemmingOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeStemmingOptions",
    validator: validate_GetDescribeStemmingOptions_773609, base: "/",
    url: url_GetDescribeStemmingOptions_773610,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeStopwordOptions_773657 = ref object of OpenApiRestCall_772597
proc url_PostDescribeStopwordOptions_773659(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeStopwordOptions_773658(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the stopwords configured for the search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773660 = query.getOrDefault("Action")
  valid_773660 = validateParameter(valid_773660, JString, required = true, default = newJString(
      "DescribeStopwordOptions"))
  if valid_773660 != nil:
    section.add "Action", valid_773660
  var valid_773661 = query.getOrDefault("Version")
  valid_773661 = validateParameter(valid_773661, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_773661 != nil:
    section.add "Version", valid_773661
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773662 = header.getOrDefault("X-Amz-Date")
  valid_773662 = validateParameter(valid_773662, JString, required = false,
                                 default = nil)
  if valid_773662 != nil:
    section.add "X-Amz-Date", valid_773662
  var valid_773663 = header.getOrDefault("X-Amz-Security-Token")
  valid_773663 = validateParameter(valid_773663, JString, required = false,
                                 default = nil)
  if valid_773663 != nil:
    section.add "X-Amz-Security-Token", valid_773663
  var valid_773664 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773664 = validateParameter(valid_773664, JString, required = false,
                                 default = nil)
  if valid_773664 != nil:
    section.add "X-Amz-Content-Sha256", valid_773664
  var valid_773665 = header.getOrDefault("X-Amz-Algorithm")
  valid_773665 = validateParameter(valid_773665, JString, required = false,
                                 default = nil)
  if valid_773665 != nil:
    section.add "X-Amz-Algorithm", valid_773665
  var valid_773666 = header.getOrDefault("X-Amz-Signature")
  valid_773666 = validateParameter(valid_773666, JString, required = false,
                                 default = nil)
  if valid_773666 != nil:
    section.add "X-Amz-Signature", valid_773666
  var valid_773667 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773667 = validateParameter(valid_773667, JString, required = false,
                                 default = nil)
  if valid_773667 != nil:
    section.add "X-Amz-SignedHeaders", valid_773667
  var valid_773668 = header.getOrDefault("X-Amz-Credential")
  valid_773668 = validateParameter(valid_773668, JString, required = false,
                                 default = nil)
  if valid_773668 != nil:
    section.add "X-Amz-Credential", valid_773668
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_773669 = formData.getOrDefault("DomainName")
  valid_773669 = validateParameter(valid_773669, JString, required = true,
                                 default = nil)
  if valid_773669 != nil:
    section.add "DomainName", valid_773669
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773670: Call_PostDescribeStopwordOptions_773657; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the stopwords configured for the search domain.
  ## 
  let valid = call_773670.validator(path, query, header, formData, body)
  let scheme = call_773670.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773670.url(scheme.get, call_773670.host, call_773670.base,
                         call_773670.route, valid.getOrDefault("path"))
  result = hook(call_773670, url, valid)

proc call*(call_773671: Call_PostDescribeStopwordOptions_773657;
          DomainName: string; Action: string = "DescribeStopwordOptions";
          Version: string = "2011-02-01"): Recallable =
  ## postDescribeStopwordOptions
  ## Gets the stopwords configured for the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773672 = newJObject()
  var formData_773673 = newJObject()
  add(formData_773673, "DomainName", newJString(DomainName))
  add(query_773672, "Action", newJString(Action))
  add(query_773672, "Version", newJString(Version))
  result = call_773671.call(nil, query_773672, nil, formData_773673, nil)

var postDescribeStopwordOptions* = Call_PostDescribeStopwordOptions_773657(
    name: "postDescribeStopwordOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeStopwordOptions",
    validator: validate_PostDescribeStopwordOptions_773658, base: "/",
    url: url_PostDescribeStopwordOptions_773659,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeStopwordOptions_773641 = ref object of OpenApiRestCall_772597
proc url_GetDescribeStopwordOptions_773643(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeStopwordOptions_773642(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the stopwords configured for the search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773644 = query.getOrDefault("Action")
  valid_773644 = validateParameter(valid_773644, JString, required = true, default = newJString(
      "DescribeStopwordOptions"))
  if valid_773644 != nil:
    section.add "Action", valid_773644
  var valid_773645 = query.getOrDefault("DomainName")
  valid_773645 = validateParameter(valid_773645, JString, required = true,
                                 default = nil)
  if valid_773645 != nil:
    section.add "DomainName", valid_773645
  var valid_773646 = query.getOrDefault("Version")
  valid_773646 = validateParameter(valid_773646, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_773646 != nil:
    section.add "Version", valid_773646
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773647 = header.getOrDefault("X-Amz-Date")
  valid_773647 = validateParameter(valid_773647, JString, required = false,
                                 default = nil)
  if valid_773647 != nil:
    section.add "X-Amz-Date", valid_773647
  var valid_773648 = header.getOrDefault("X-Amz-Security-Token")
  valid_773648 = validateParameter(valid_773648, JString, required = false,
                                 default = nil)
  if valid_773648 != nil:
    section.add "X-Amz-Security-Token", valid_773648
  var valid_773649 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773649 = validateParameter(valid_773649, JString, required = false,
                                 default = nil)
  if valid_773649 != nil:
    section.add "X-Amz-Content-Sha256", valid_773649
  var valid_773650 = header.getOrDefault("X-Amz-Algorithm")
  valid_773650 = validateParameter(valid_773650, JString, required = false,
                                 default = nil)
  if valid_773650 != nil:
    section.add "X-Amz-Algorithm", valid_773650
  var valid_773651 = header.getOrDefault("X-Amz-Signature")
  valid_773651 = validateParameter(valid_773651, JString, required = false,
                                 default = nil)
  if valid_773651 != nil:
    section.add "X-Amz-Signature", valid_773651
  var valid_773652 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773652 = validateParameter(valid_773652, JString, required = false,
                                 default = nil)
  if valid_773652 != nil:
    section.add "X-Amz-SignedHeaders", valid_773652
  var valid_773653 = header.getOrDefault("X-Amz-Credential")
  valid_773653 = validateParameter(valid_773653, JString, required = false,
                                 default = nil)
  if valid_773653 != nil:
    section.add "X-Amz-Credential", valid_773653
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773654: Call_GetDescribeStopwordOptions_773641; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the stopwords configured for the search domain.
  ## 
  let valid = call_773654.validator(path, query, header, formData, body)
  let scheme = call_773654.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773654.url(scheme.get, call_773654.host, call_773654.base,
                         call_773654.route, valid.getOrDefault("path"))
  result = hook(call_773654, url, valid)

proc call*(call_773655: Call_GetDescribeStopwordOptions_773641; DomainName: string;
          Action: string = "DescribeStopwordOptions"; Version: string = "2011-02-01"): Recallable =
  ## getDescribeStopwordOptions
  ## Gets the stopwords configured for the search domain.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_773656 = newJObject()
  add(query_773656, "Action", newJString(Action))
  add(query_773656, "DomainName", newJString(DomainName))
  add(query_773656, "Version", newJString(Version))
  result = call_773655.call(nil, query_773656, nil, nil, nil)

var getDescribeStopwordOptions* = Call_GetDescribeStopwordOptions_773641(
    name: "getDescribeStopwordOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeStopwordOptions",
    validator: validate_GetDescribeStopwordOptions_773642, base: "/",
    url: url_GetDescribeStopwordOptions_773643,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeSynonymOptions_773690 = ref object of OpenApiRestCall_772597
proc url_PostDescribeSynonymOptions_773692(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeSynonymOptions_773691(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the synonym dictionary configured for the search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773693 = query.getOrDefault("Action")
  valid_773693 = validateParameter(valid_773693, JString, required = true,
                                 default = newJString("DescribeSynonymOptions"))
  if valid_773693 != nil:
    section.add "Action", valid_773693
  var valid_773694 = query.getOrDefault("Version")
  valid_773694 = validateParameter(valid_773694, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_773694 != nil:
    section.add "Version", valid_773694
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773695 = header.getOrDefault("X-Amz-Date")
  valid_773695 = validateParameter(valid_773695, JString, required = false,
                                 default = nil)
  if valid_773695 != nil:
    section.add "X-Amz-Date", valid_773695
  var valid_773696 = header.getOrDefault("X-Amz-Security-Token")
  valid_773696 = validateParameter(valid_773696, JString, required = false,
                                 default = nil)
  if valid_773696 != nil:
    section.add "X-Amz-Security-Token", valid_773696
  var valid_773697 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773697 = validateParameter(valid_773697, JString, required = false,
                                 default = nil)
  if valid_773697 != nil:
    section.add "X-Amz-Content-Sha256", valid_773697
  var valid_773698 = header.getOrDefault("X-Amz-Algorithm")
  valid_773698 = validateParameter(valid_773698, JString, required = false,
                                 default = nil)
  if valid_773698 != nil:
    section.add "X-Amz-Algorithm", valid_773698
  var valid_773699 = header.getOrDefault("X-Amz-Signature")
  valid_773699 = validateParameter(valid_773699, JString, required = false,
                                 default = nil)
  if valid_773699 != nil:
    section.add "X-Amz-Signature", valid_773699
  var valid_773700 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773700 = validateParameter(valid_773700, JString, required = false,
                                 default = nil)
  if valid_773700 != nil:
    section.add "X-Amz-SignedHeaders", valid_773700
  var valid_773701 = header.getOrDefault("X-Amz-Credential")
  valid_773701 = validateParameter(valid_773701, JString, required = false,
                                 default = nil)
  if valid_773701 != nil:
    section.add "X-Amz-Credential", valid_773701
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_773702 = formData.getOrDefault("DomainName")
  valid_773702 = validateParameter(valid_773702, JString, required = true,
                                 default = nil)
  if valid_773702 != nil:
    section.add "DomainName", valid_773702
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773703: Call_PostDescribeSynonymOptions_773690; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the synonym dictionary configured for the search domain.
  ## 
  let valid = call_773703.validator(path, query, header, formData, body)
  let scheme = call_773703.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773703.url(scheme.get, call_773703.host, call_773703.base,
                         call_773703.route, valid.getOrDefault("path"))
  result = hook(call_773703, url, valid)

proc call*(call_773704: Call_PostDescribeSynonymOptions_773690; DomainName: string;
          Action: string = "DescribeSynonymOptions"; Version: string = "2011-02-01"): Recallable =
  ## postDescribeSynonymOptions
  ## Gets the synonym dictionary configured for the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773705 = newJObject()
  var formData_773706 = newJObject()
  add(formData_773706, "DomainName", newJString(DomainName))
  add(query_773705, "Action", newJString(Action))
  add(query_773705, "Version", newJString(Version))
  result = call_773704.call(nil, query_773705, nil, formData_773706, nil)

var postDescribeSynonymOptions* = Call_PostDescribeSynonymOptions_773690(
    name: "postDescribeSynonymOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeSynonymOptions",
    validator: validate_PostDescribeSynonymOptions_773691, base: "/",
    url: url_PostDescribeSynonymOptions_773692,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeSynonymOptions_773674 = ref object of OpenApiRestCall_772597
proc url_GetDescribeSynonymOptions_773676(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeSynonymOptions_773675(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the synonym dictionary configured for the search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773677 = query.getOrDefault("Action")
  valid_773677 = validateParameter(valid_773677, JString, required = true,
                                 default = newJString("DescribeSynonymOptions"))
  if valid_773677 != nil:
    section.add "Action", valid_773677
  var valid_773678 = query.getOrDefault("DomainName")
  valid_773678 = validateParameter(valid_773678, JString, required = true,
                                 default = nil)
  if valid_773678 != nil:
    section.add "DomainName", valid_773678
  var valid_773679 = query.getOrDefault("Version")
  valid_773679 = validateParameter(valid_773679, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_773679 != nil:
    section.add "Version", valid_773679
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773680 = header.getOrDefault("X-Amz-Date")
  valid_773680 = validateParameter(valid_773680, JString, required = false,
                                 default = nil)
  if valid_773680 != nil:
    section.add "X-Amz-Date", valid_773680
  var valid_773681 = header.getOrDefault("X-Amz-Security-Token")
  valid_773681 = validateParameter(valid_773681, JString, required = false,
                                 default = nil)
  if valid_773681 != nil:
    section.add "X-Amz-Security-Token", valid_773681
  var valid_773682 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773682 = validateParameter(valid_773682, JString, required = false,
                                 default = nil)
  if valid_773682 != nil:
    section.add "X-Amz-Content-Sha256", valid_773682
  var valid_773683 = header.getOrDefault("X-Amz-Algorithm")
  valid_773683 = validateParameter(valid_773683, JString, required = false,
                                 default = nil)
  if valid_773683 != nil:
    section.add "X-Amz-Algorithm", valid_773683
  var valid_773684 = header.getOrDefault("X-Amz-Signature")
  valid_773684 = validateParameter(valid_773684, JString, required = false,
                                 default = nil)
  if valid_773684 != nil:
    section.add "X-Amz-Signature", valid_773684
  var valid_773685 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773685 = validateParameter(valid_773685, JString, required = false,
                                 default = nil)
  if valid_773685 != nil:
    section.add "X-Amz-SignedHeaders", valid_773685
  var valid_773686 = header.getOrDefault("X-Amz-Credential")
  valid_773686 = validateParameter(valid_773686, JString, required = false,
                                 default = nil)
  if valid_773686 != nil:
    section.add "X-Amz-Credential", valid_773686
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773687: Call_GetDescribeSynonymOptions_773674; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the synonym dictionary configured for the search domain.
  ## 
  let valid = call_773687.validator(path, query, header, formData, body)
  let scheme = call_773687.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773687.url(scheme.get, call_773687.host, call_773687.base,
                         call_773687.route, valid.getOrDefault("path"))
  result = hook(call_773687, url, valid)

proc call*(call_773688: Call_GetDescribeSynonymOptions_773674; DomainName: string;
          Action: string = "DescribeSynonymOptions"; Version: string = "2011-02-01"): Recallable =
  ## getDescribeSynonymOptions
  ## Gets the synonym dictionary configured for the search domain.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_773689 = newJObject()
  add(query_773689, "Action", newJString(Action))
  add(query_773689, "DomainName", newJString(DomainName))
  add(query_773689, "Version", newJString(Version))
  result = call_773688.call(nil, query_773689, nil, nil, nil)

var getDescribeSynonymOptions* = Call_GetDescribeSynonymOptions_773674(
    name: "getDescribeSynonymOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeSynonymOptions",
    validator: validate_GetDescribeSynonymOptions_773675, base: "/",
    url: url_GetDescribeSynonymOptions_773676,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostIndexDocuments_773723 = ref object of OpenApiRestCall_772597
proc url_PostIndexDocuments_773725(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostIndexDocuments_773724(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Tells the search domain to start indexing its documents using the latest text processing options and <code>IndexFields</code>. This operation must be invoked to make options whose <a>OptionStatus</a> has <code>OptionState</code> of <code>RequiresIndexDocuments</code> visible in search results.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773726 = query.getOrDefault("Action")
  valid_773726 = validateParameter(valid_773726, JString, required = true,
                                 default = newJString("IndexDocuments"))
  if valid_773726 != nil:
    section.add "Action", valid_773726
  var valid_773727 = query.getOrDefault("Version")
  valid_773727 = validateParameter(valid_773727, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_773727 != nil:
    section.add "Version", valid_773727
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773728 = header.getOrDefault("X-Amz-Date")
  valid_773728 = validateParameter(valid_773728, JString, required = false,
                                 default = nil)
  if valid_773728 != nil:
    section.add "X-Amz-Date", valid_773728
  var valid_773729 = header.getOrDefault("X-Amz-Security-Token")
  valid_773729 = validateParameter(valid_773729, JString, required = false,
                                 default = nil)
  if valid_773729 != nil:
    section.add "X-Amz-Security-Token", valid_773729
  var valid_773730 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773730 = validateParameter(valid_773730, JString, required = false,
                                 default = nil)
  if valid_773730 != nil:
    section.add "X-Amz-Content-Sha256", valid_773730
  var valid_773731 = header.getOrDefault("X-Amz-Algorithm")
  valid_773731 = validateParameter(valid_773731, JString, required = false,
                                 default = nil)
  if valid_773731 != nil:
    section.add "X-Amz-Algorithm", valid_773731
  var valid_773732 = header.getOrDefault("X-Amz-Signature")
  valid_773732 = validateParameter(valid_773732, JString, required = false,
                                 default = nil)
  if valid_773732 != nil:
    section.add "X-Amz-Signature", valid_773732
  var valid_773733 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773733 = validateParameter(valid_773733, JString, required = false,
                                 default = nil)
  if valid_773733 != nil:
    section.add "X-Amz-SignedHeaders", valid_773733
  var valid_773734 = header.getOrDefault("X-Amz-Credential")
  valid_773734 = validateParameter(valid_773734, JString, required = false,
                                 default = nil)
  if valid_773734 != nil:
    section.add "X-Amz-Credential", valid_773734
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_773735 = formData.getOrDefault("DomainName")
  valid_773735 = validateParameter(valid_773735, JString, required = true,
                                 default = nil)
  if valid_773735 != nil:
    section.add "DomainName", valid_773735
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773736: Call_PostIndexDocuments_773723; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Tells the search domain to start indexing its documents using the latest text processing options and <code>IndexFields</code>. This operation must be invoked to make options whose <a>OptionStatus</a> has <code>OptionState</code> of <code>RequiresIndexDocuments</code> visible in search results.
  ## 
  let valid = call_773736.validator(path, query, header, formData, body)
  let scheme = call_773736.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773736.url(scheme.get, call_773736.host, call_773736.base,
                         call_773736.route, valid.getOrDefault("path"))
  result = hook(call_773736, url, valid)

proc call*(call_773737: Call_PostIndexDocuments_773723; DomainName: string;
          Action: string = "IndexDocuments"; Version: string = "2011-02-01"): Recallable =
  ## postIndexDocuments
  ## Tells the search domain to start indexing its documents using the latest text processing options and <code>IndexFields</code>. This operation must be invoked to make options whose <a>OptionStatus</a> has <code>OptionState</code> of <code>RequiresIndexDocuments</code> visible in search results.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773738 = newJObject()
  var formData_773739 = newJObject()
  add(formData_773739, "DomainName", newJString(DomainName))
  add(query_773738, "Action", newJString(Action))
  add(query_773738, "Version", newJString(Version))
  result = call_773737.call(nil, query_773738, nil, formData_773739, nil)

var postIndexDocuments* = Call_PostIndexDocuments_773723(
    name: "postIndexDocuments", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=IndexDocuments",
    validator: validate_PostIndexDocuments_773724, base: "/",
    url: url_PostIndexDocuments_773725, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIndexDocuments_773707 = ref object of OpenApiRestCall_772597
proc url_GetIndexDocuments_773709(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetIndexDocuments_773708(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Tells the search domain to start indexing its documents using the latest text processing options and <code>IndexFields</code>. This operation must be invoked to make options whose <a>OptionStatus</a> has <code>OptionState</code> of <code>RequiresIndexDocuments</code> visible in search results.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773710 = query.getOrDefault("Action")
  valid_773710 = validateParameter(valid_773710, JString, required = true,
                                 default = newJString("IndexDocuments"))
  if valid_773710 != nil:
    section.add "Action", valid_773710
  var valid_773711 = query.getOrDefault("DomainName")
  valid_773711 = validateParameter(valid_773711, JString, required = true,
                                 default = nil)
  if valid_773711 != nil:
    section.add "DomainName", valid_773711
  var valid_773712 = query.getOrDefault("Version")
  valid_773712 = validateParameter(valid_773712, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_773712 != nil:
    section.add "Version", valid_773712
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773713 = header.getOrDefault("X-Amz-Date")
  valid_773713 = validateParameter(valid_773713, JString, required = false,
                                 default = nil)
  if valid_773713 != nil:
    section.add "X-Amz-Date", valid_773713
  var valid_773714 = header.getOrDefault("X-Amz-Security-Token")
  valid_773714 = validateParameter(valid_773714, JString, required = false,
                                 default = nil)
  if valid_773714 != nil:
    section.add "X-Amz-Security-Token", valid_773714
  var valid_773715 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773715 = validateParameter(valid_773715, JString, required = false,
                                 default = nil)
  if valid_773715 != nil:
    section.add "X-Amz-Content-Sha256", valid_773715
  var valid_773716 = header.getOrDefault("X-Amz-Algorithm")
  valid_773716 = validateParameter(valid_773716, JString, required = false,
                                 default = nil)
  if valid_773716 != nil:
    section.add "X-Amz-Algorithm", valid_773716
  var valid_773717 = header.getOrDefault("X-Amz-Signature")
  valid_773717 = validateParameter(valid_773717, JString, required = false,
                                 default = nil)
  if valid_773717 != nil:
    section.add "X-Amz-Signature", valid_773717
  var valid_773718 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773718 = validateParameter(valid_773718, JString, required = false,
                                 default = nil)
  if valid_773718 != nil:
    section.add "X-Amz-SignedHeaders", valid_773718
  var valid_773719 = header.getOrDefault("X-Amz-Credential")
  valid_773719 = validateParameter(valid_773719, JString, required = false,
                                 default = nil)
  if valid_773719 != nil:
    section.add "X-Amz-Credential", valid_773719
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773720: Call_GetIndexDocuments_773707; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Tells the search domain to start indexing its documents using the latest text processing options and <code>IndexFields</code>. This operation must be invoked to make options whose <a>OptionStatus</a> has <code>OptionState</code> of <code>RequiresIndexDocuments</code> visible in search results.
  ## 
  let valid = call_773720.validator(path, query, header, formData, body)
  let scheme = call_773720.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773720.url(scheme.get, call_773720.host, call_773720.base,
                         call_773720.route, valid.getOrDefault("path"))
  result = hook(call_773720, url, valid)

proc call*(call_773721: Call_GetIndexDocuments_773707; DomainName: string;
          Action: string = "IndexDocuments"; Version: string = "2011-02-01"): Recallable =
  ## getIndexDocuments
  ## Tells the search domain to start indexing its documents using the latest text processing options and <code>IndexFields</code>. This operation must be invoked to make options whose <a>OptionStatus</a> has <code>OptionState</code> of <code>RequiresIndexDocuments</code> visible in search results.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_773722 = newJObject()
  add(query_773722, "Action", newJString(Action))
  add(query_773722, "DomainName", newJString(DomainName))
  add(query_773722, "Version", newJString(Version))
  result = call_773721.call(nil, query_773722, nil, nil, nil)

var getIndexDocuments* = Call_GetIndexDocuments_773707(name: "getIndexDocuments",
    meth: HttpMethod.HttpGet, host: "cloudsearch.amazonaws.com",
    route: "/#Action=IndexDocuments", validator: validate_GetIndexDocuments_773708,
    base: "/", url: url_GetIndexDocuments_773709,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateAvailabilityOptions_773757 = ref object of OpenApiRestCall_772597
proc url_PostUpdateAvailabilityOptions_773759(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostUpdateAvailabilityOptions_773758(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773760 = query.getOrDefault("Action")
  valid_773760 = validateParameter(valid_773760, JString, required = true, default = newJString(
      "UpdateAvailabilityOptions"))
  if valid_773760 != nil:
    section.add "Action", valid_773760
  var valid_773761 = query.getOrDefault("Version")
  valid_773761 = validateParameter(valid_773761, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_773761 != nil:
    section.add "Version", valid_773761
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773762 = header.getOrDefault("X-Amz-Date")
  valid_773762 = validateParameter(valid_773762, JString, required = false,
                                 default = nil)
  if valid_773762 != nil:
    section.add "X-Amz-Date", valid_773762
  var valid_773763 = header.getOrDefault("X-Amz-Security-Token")
  valid_773763 = validateParameter(valid_773763, JString, required = false,
                                 default = nil)
  if valid_773763 != nil:
    section.add "X-Amz-Security-Token", valid_773763
  var valid_773764 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773764 = validateParameter(valid_773764, JString, required = false,
                                 default = nil)
  if valid_773764 != nil:
    section.add "X-Amz-Content-Sha256", valid_773764
  var valid_773765 = header.getOrDefault("X-Amz-Algorithm")
  valid_773765 = validateParameter(valid_773765, JString, required = false,
                                 default = nil)
  if valid_773765 != nil:
    section.add "X-Amz-Algorithm", valid_773765
  var valid_773766 = header.getOrDefault("X-Amz-Signature")
  valid_773766 = validateParameter(valid_773766, JString, required = false,
                                 default = nil)
  if valid_773766 != nil:
    section.add "X-Amz-Signature", valid_773766
  var valid_773767 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773767 = validateParameter(valid_773767, JString, required = false,
                                 default = nil)
  if valid_773767 != nil:
    section.add "X-Amz-SignedHeaders", valid_773767
  var valid_773768 = header.getOrDefault("X-Amz-Credential")
  valid_773768 = validateParameter(valid_773768, JString, required = false,
                                 default = nil)
  if valid_773768 != nil:
    section.add "X-Amz-Credential", valid_773768
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   MultiAZ: JBool (required)
  ##          : You expand an existing search domain to a second Availability Zone by setting the Multi-AZ option to true. Similarly, you can turn off the Multi-AZ option to downgrade the domain to a single Availability Zone by setting the Multi-AZ option to <code>false</code>. 
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_773769 = formData.getOrDefault("DomainName")
  valid_773769 = validateParameter(valid_773769, JString, required = true,
                                 default = nil)
  if valid_773769 != nil:
    section.add "DomainName", valid_773769
  var valid_773770 = formData.getOrDefault("MultiAZ")
  valid_773770 = validateParameter(valid_773770, JBool, required = true, default = nil)
  if valid_773770 != nil:
    section.add "MultiAZ", valid_773770
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773771: Call_PostUpdateAvailabilityOptions_773757; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_773771.validator(path, query, header, formData, body)
  let scheme = call_773771.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773771.url(scheme.get, call_773771.host, call_773771.base,
                         call_773771.route, valid.getOrDefault("path"))
  result = hook(call_773771, url, valid)

proc call*(call_773772: Call_PostUpdateAvailabilityOptions_773757;
          DomainName: string; MultiAZ: bool;
          Action: string = "UpdateAvailabilityOptions";
          Version: string = "2011-02-01"): Recallable =
  ## postUpdateAvailabilityOptions
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   MultiAZ: bool (required)
  ##          : You expand an existing search domain to a second Availability Zone by setting the Multi-AZ option to true. Similarly, you can turn off the Multi-AZ option to downgrade the domain to a single Availability Zone by setting the Multi-AZ option to <code>false</code>. 
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773773 = newJObject()
  var formData_773774 = newJObject()
  add(formData_773774, "DomainName", newJString(DomainName))
  add(formData_773774, "MultiAZ", newJBool(MultiAZ))
  add(query_773773, "Action", newJString(Action))
  add(query_773773, "Version", newJString(Version))
  result = call_773772.call(nil, query_773773, nil, formData_773774, nil)

var postUpdateAvailabilityOptions* = Call_PostUpdateAvailabilityOptions_773757(
    name: "postUpdateAvailabilityOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateAvailabilityOptions",
    validator: validate_PostUpdateAvailabilityOptions_773758, base: "/",
    url: url_PostUpdateAvailabilityOptions_773759,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateAvailabilityOptions_773740 = ref object of OpenApiRestCall_772597
proc url_GetUpdateAvailabilityOptions_773742(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetUpdateAvailabilityOptions_773741(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MultiAZ: JBool (required)
  ##          : You expand an existing search domain to a second Availability Zone by setting the Multi-AZ option to true. Similarly, you can turn off the Multi-AZ option to downgrade the domain to a single Availability Zone by setting the Multi-AZ option to <code>false</code>. 
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `MultiAZ` field"
  var valid_773743 = query.getOrDefault("MultiAZ")
  valid_773743 = validateParameter(valid_773743, JBool, required = true, default = nil)
  if valid_773743 != nil:
    section.add "MultiAZ", valid_773743
  var valid_773744 = query.getOrDefault("Action")
  valid_773744 = validateParameter(valid_773744, JString, required = true, default = newJString(
      "UpdateAvailabilityOptions"))
  if valid_773744 != nil:
    section.add "Action", valid_773744
  var valid_773745 = query.getOrDefault("DomainName")
  valid_773745 = validateParameter(valid_773745, JString, required = true,
                                 default = nil)
  if valid_773745 != nil:
    section.add "DomainName", valid_773745
  var valid_773746 = query.getOrDefault("Version")
  valid_773746 = validateParameter(valid_773746, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_773746 != nil:
    section.add "Version", valid_773746
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773747 = header.getOrDefault("X-Amz-Date")
  valid_773747 = validateParameter(valid_773747, JString, required = false,
                                 default = nil)
  if valid_773747 != nil:
    section.add "X-Amz-Date", valid_773747
  var valid_773748 = header.getOrDefault("X-Amz-Security-Token")
  valid_773748 = validateParameter(valid_773748, JString, required = false,
                                 default = nil)
  if valid_773748 != nil:
    section.add "X-Amz-Security-Token", valid_773748
  var valid_773749 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773749 = validateParameter(valid_773749, JString, required = false,
                                 default = nil)
  if valid_773749 != nil:
    section.add "X-Amz-Content-Sha256", valid_773749
  var valid_773750 = header.getOrDefault("X-Amz-Algorithm")
  valid_773750 = validateParameter(valid_773750, JString, required = false,
                                 default = nil)
  if valid_773750 != nil:
    section.add "X-Amz-Algorithm", valid_773750
  var valid_773751 = header.getOrDefault("X-Amz-Signature")
  valid_773751 = validateParameter(valid_773751, JString, required = false,
                                 default = nil)
  if valid_773751 != nil:
    section.add "X-Amz-Signature", valid_773751
  var valid_773752 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773752 = validateParameter(valid_773752, JString, required = false,
                                 default = nil)
  if valid_773752 != nil:
    section.add "X-Amz-SignedHeaders", valid_773752
  var valid_773753 = header.getOrDefault("X-Amz-Credential")
  valid_773753 = validateParameter(valid_773753, JString, required = false,
                                 default = nil)
  if valid_773753 != nil:
    section.add "X-Amz-Credential", valid_773753
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773754: Call_GetUpdateAvailabilityOptions_773740; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_773754.validator(path, query, header, formData, body)
  let scheme = call_773754.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773754.url(scheme.get, call_773754.host, call_773754.base,
                         call_773754.route, valid.getOrDefault("path"))
  result = hook(call_773754, url, valid)

proc call*(call_773755: Call_GetUpdateAvailabilityOptions_773740; MultiAZ: bool;
          DomainName: string; Action: string = "UpdateAvailabilityOptions";
          Version: string = "2011-02-01"): Recallable =
  ## getUpdateAvailabilityOptions
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   MultiAZ: bool (required)
  ##          : You expand an existing search domain to a second Availability Zone by setting the Multi-AZ option to true. Similarly, you can turn off the Multi-AZ option to downgrade the domain to a single Availability Zone by setting the Multi-AZ option to <code>false</code>. 
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_773756 = newJObject()
  add(query_773756, "MultiAZ", newJBool(MultiAZ))
  add(query_773756, "Action", newJString(Action))
  add(query_773756, "DomainName", newJString(DomainName))
  add(query_773756, "Version", newJString(Version))
  result = call_773755.call(nil, query_773756, nil, nil, nil)

var getUpdateAvailabilityOptions* = Call_GetUpdateAvailabilityOptions_773740(
    name: "getUpdateAvailabilityOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateAvailabilityOptions",
    validator: validate_GetUpdateAvailabilityOptions_773741, base: "/",
    url: url_GetUpdateAvailabilityOptions_773742,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateDefaultSearchField_773792 = ref object of OpenApiRestCall_772597
proc url_PostUpdateDefaultSearchField_773794(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostUpdateDefaultSearchField_773793(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures the default search field for the search domain. The default search field is the text field that is searched when a search request does not specify which fields to search. By default, it is configured to include the contents of all of the domain's text fields. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773795 = query.getOrDefault("Action")
  valid_773795 = validateParameter(valid_773795, JString, required = true, default = newJString(
      "UpdateDefaultSearchField"))
  if valid_773795 != nil:
    section.add "Action", valid_773795
  var valid_773796 = query.getOrDefault("Version")
  valid_773796 = validateParameter(valid_773796, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_773796 != nil:
    section.add "Version", valid_773796
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773797 = header.getOrDefault("X-Amz-Date")
  valid_773797 = validateParameter(valid_773797, JString, required = false,
                                 default = nil)
  if valid_773797 != nil:
    section.add "X-Amz-Date", valid_773797
  var valid_773798 = header.getOrDefault("X-Amz-Security-Token")
  valid_773798 = validateParameter(valid_773798, JString, required = false,
                                 default = nil)
  if valid_773798 != nil:
    section.add "X-Amz-Security-Token", valid_773798
  var valid_773799 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773799 = validateParameter(valid_773799, JString, required = false,
                                 default = nil)
  if valid_773799 != nil:
    section.add "X-Amz-Content-Sha256", valid_773799
  var valid_773800 = header.getOrDefault("X-Amz-Algorithm")
  valid_773800 = validateParameter(valid_773800, JString, required = false,
                                 default = nil)
  if valid_773800 != nil:
    section.add "X-Amz-Algorithm", valid_773800
  var valid_773801 = header.getOrDefault("X-Amz-Signature")
  valid_773801 = validateParameter(valid_773801, JString, required = false,
                                 default = nil)
  if valid_773801 != nil:
    section.add "X-Amz-Signature", valid_773801
  var valid_773802 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773802 = validateParameter(valid_773802, JString, required = false,
                                 default = nil)
  if valid_773802 != nil:
    section.add "X-Amz-SignedHeaders", valid_773802
  var valid_773803 = header.getOrDefault("X-Amz-Credential")
  valid_773803 = validateParameter(valid_773803, JString, required = false,
                                 default = nil)
  if valid_773803 != nil:
    section.add "X-Amz-Credential", valid_773803
  result.add "header", section
  ## parameters in `formData` object:
  ##   DefaultSearchField: JString (required)
  ##                     : The text field to search if the search request does not specify which field to search. The default search field is used when search terms are specified with the <code>q</code> parameter, or if a match expression specified with the <code>bq</code> parameter does not constrain the search to a particular field. The default is an empty string, which automatically searches all text fields.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DefaultSearchField` field"
  var valid_773804 = formData.getOrDefault("DefaultSearchField")
  valid_773804 = validateParameter(valid_773804, JString, required = true,
                                 default = nil)
  if valid_773804 != nil:
    section.add "DefaultSearchField", valid_773804
  var valid_773805 = formData.getOrDefault("DomainName")
  valid_773805 = validateParameter(valid_773805, JString, required = true,
                                 default = nil)
  if valid_773805 != nil:
    section.add "DomainName", valid_773805
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773806: Call_PostUpdateDefaultSearchField_773792; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the default search field for the search domain. The default search field is the text field that is searched when a search request does not specify which fields to search. By default, it is configured to include the contents of all of the domain's text fields. 
  ## 
  let valid = call_773806.validator(path, query, header, formData, body)
  let scheme = call_773806.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773806.url(scheme.get, call_773806.host, call_773806.base,
                         call_773806.route, valid.getOrDefault("path"))
  result = hook(call_773806, url, valid)

proc call*(call_773807: Call_PostUpdateDefaultSearchField_773792;
          DefaultSearchField: string; DomainName: string;
          Action: string = "UpdateDefaultSearchField";
          Version: string = "2011-02-01"): Recallable =
  ## postUpdateDefaultSearchField
  ## Configures the default search field for the search domain. The default search field is the text field that is searched when a search request does not specify which fields to search. By default, it is configured to include the contents of all of the domain's text fields. 
  ##   DefaultSearchField: string (required)
  ##                     : The text field to search if the search request does not specify which field to search. The default search field is used when search terms are specified with the <code>q</code> parameter, or if a match expression specified with the <code>bq</code> parameter does not constrain the search to a particular field. The default is an empty string, which automatically searches all text fields.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773808 = newJObject()
  var formData_773809 = newJObject()
  add(formData_773809, "DefaultSearchField", newJString(DefaultSearchField))
  add(formData_773809, "DomainName", newJString(DomainName))
  add(query_773808, "Action", newJString(Action))
  add(query_773808, "Version", newJString(Version))
  result = call_773807.call(nil, query_773808, nil, formData_773809, nil)

var postUpdateDefaultSearchField* = Call_PostUpdateDefaultSearchField_773792(
    name: "postUpdateDefaultSearchField", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateDefaultSearchField",
    validator: validate_PostUpdateDefaultSearchField_773793, base: "/",
    url: url_PostUpdateDefaultSearchField_773794,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateDefaultSearchField_773775 = ref object of OpenApiRestCall_772597
proc url_GetUpdateDefaultSearchField_773777(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetUpdateDefaultSearchField_773776(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures the default search field for the search domain. The default search field is the text field that is searched when a search request does not specify which fields to search. By default, it is configured to include the contents of all of the domain's text fields. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   DefaultSearchField: JString (required)
  ##                     : The text field to search if the search request does not specify which field to search. The default search field is used when search terms are specified with the <code>q</code> parameter, or if a match expression specified with the <code>bq</code> parameter does not constrain the search to a particular field. The default is an empty string, which automatically searches all text fields.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773778 = query.getOrDefault("Action")
  valid_773778 = validateParameter(valid_773778, JString, required = true, default = newJString(
      "UpdateDefaultSearchField"))
  if valid_773778 != nil:
    section.add "Action", valid_773778
  var valid_773779 = query.getOrDefault("DomainName")
  valid_773779 = validateParameter(valid_773779, JString, required = true,
                                 default = nil)
  if valid_773779 != nil:
    section.add "DomainName", valid_773779
  var valid_773780 = query.getOrDefault("DefaultSearchField")
  valid_773780 = validateParameter(valid_773780, JString, required = true,
                                 default = nil)
  if valid_773780 != nil:
    section.add "DefaultSearchField", valid_773780
  var valid_773781 = query.getOrDefault("Version")
  valid_773781 = validateParameter(valid_773781, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_773781 != nil:
    section.add "Version", valid_773781
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773782 = header.getOrDefault("X-Amz-Date")
  valid_773782 = validateParameter(valid_773782, JString, required = false,
                                 default = nil)
  if valid_773782 != nil:
    section.add "X-Amz-Date", valid_773782
  var valid_773783 = header.getOrDefault("X-Amz-Security-Token")
  valid_773783 = validateParameter(valid_773783, JString, required = false,
                                 default = nil)
  if valid_773783 != nil:
    section.add "X-Amz-Security-Token", valid_773783
  var valid_773784 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773784 = validateParameter(valid_773784, JString, required = false,
                                 default = nil)
  if valid_773784 != nil:
    section.add "X-Amz-Content-Sha256", valid_773784
  var valid_773785 = header.getOrDefault("X-Amz-Algorithm")
  valid_773785 = validateParameter(valid_773785, JString, required = false,
                                 default = nil)
  if valid_773785 != nil:
    section.add "X-Amz-Algorithm", valid_773785
  var valid_773786 = header.getOrDefault("X-Amz-Signature")
  valid_773786 = validateParameter(valid_773786, JString, required = false,
                                 default = nil)
  if valid_773786 != nil:
    section.add "X-Amz-Signature", valid_773786
  var valid_773787 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773787 = validateParameter(valid_773787, JString, required = false,
                                 default = nil)
  if valid_773787 != nil:
    section.add "X-Amz-SignedHeaders", valid_773787
  var valid_773788 = header.getOrDefault("X-Amz-Credential")
  valid_773788 = validateParameter(valid_773788, JString, required = false,
                                 default = nil)
  if valid_773788 != nil:
    section.add "X-Amz-Credential", valid_773788
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773789: Call_GetUpdateDefaultSearchField_773775; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the default search field for the search domain. The default search field is the text field that is searched when a search request does not specify which fields to search. By default, it is configured to include the contents of all of the domain's text fields. 
  ## 
  let valid = call_773789.validator(path, query, header, formData, body)
  let scheme = call_773789.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773789.url(scheme.get, call_773789.host, call_773789.base,
                         call_773789.route, valid.getOrDefault("path"))
  result = hook(call_773789, url, valid)

proc call*(call_773790: Call_GetUpdateDefaultSearchField_773775;
          DomainName: string; DefaultSearchField: string;
          Action: string = "UpdateDefaultSearchField";
          Version: string = "2011-02-01"): Recallable =
  ## getUpdateDefaultSearchField
  ## Configures the default search field for the search domain. The default search field is the text field that is searched when a search request does not specify which fields to search. By default, it is configured to include the contents of all of the domain's text fields. 
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   DefaultSearchField: string (required)
  ##                     : The text field to search if the search request does not specify which field to search. The default search field is used when search terms are specified with the <code>q</code> parameter, or if a match expression specified with the <code>bq</code> parameter does not constrain the search to a particular field. The default is an empty string, which automatically searches all text fields.
  ##   Version: string (required)
  var query_773791 = newJObject()
  add(query_773791, "Action", newJString(Action))
  add(query_773791, "DomainName", newJString(DomainName))
  add(query_773791, "DefaultSearchField", newJString(DefaultSearchField))
  add(query_773791, "Version", newJString(Version))
  result = call_773790.call(nil, query_773791, nil, nil, nil)

var getUpdateDefaultSearchField* = Call_GetUpdateDefaultSearchField_773775(
    name: "getUpdateDefaultSearchField", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateDefaultSearchField",
    validator: validate_GetUpdateDefaultSearchField_773776, base: "/",
    url: url_GetUpdateDefaultSearchField_773777,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateServiceAccessPolicies_773827 = ref object of OpenApiRestCall_772597
proc url_PostUpdateServiceAccessPolicies_773829(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostUpdateServiceAccessPolicies_773828(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures the policies that control access to the domain's document and search services. The maximum size of an access policy document is 100 KB.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773830 = query.getOrDefault("Action")
  valid_773830 = validateParameter(valid_773830, JString, required = true, default = newJString(
      "UpdateServiceAccessPolicies"))
  if valid_773830 != nil:
    section.add "Action", valid_773830
  var valid_773831 = query.getOrDefault("Version")
  valid_773831 = validateParameter(valid_773831, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_773831 != nil:
    section.add "Version", valid_773831
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773832 = header.getOrDefault("X-Amz-Date")
  valid_773832 = validateParameter(valid_773832, JString, required = false,
                                 default = nil)
  if valid_773832 != nil:
    section.add "X-Amz-Date", valid_773832
  var valid_773833 = header.getOrDefault("X-Amz-Security-Token")
  valid_773833 = validateParameter(valid_773833, JString, required = false,
                                 default = nil)
  if valid_773833 != nil:
    section.add "X-Amz-Security-Token", valid_773833
  var valid_773834 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773834 = validateParameter(valid_773834, JString, required = false,
                                 default = nil)
  if valid_773834 != nil:
    section.add "X-Amz-Content-Sha256", valid_773834
  var valid_773835 = header.getOrDefault("X-Amz-Algorithm")
  valid_773835 = validateParameter(valid_773835, JString, required = false,
                                 default = nil)
  if valid_773835 != nil:
    section.add "X-Amz-Algorithm", valid_773835
  var valid_773836 = header.getOrDefault("X-Amz-Signature")
  valid_773836 = validateParameter(valid_773836, JString, required = false,
                                 default = nil)
  if valid_773836 != nil:
    section.add "X-Amz-Signature", valid_773836
  var valid_773837 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773837 = validateParameter(valid_773837, JString, required = false,
                                 default = nil)
  if valid_773837 != nil:
    section.add "X-Amz-SignedHeaders", valid_773837
  var valid_773838 = header.getOrDefault("X-Amz-Credential")
  valid_773838 = validateParameter(valid_773838, JString, required = false,
                                 default = nil)
  if valid_773838 != nil:
    section.add "X-Amz-Credential", valid_773838
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   AccessPolicies: JString (required)
  ##                 : <p>An IAM access policy as described in <a 
  ## href="http://docs.aws.amazon.com/IAM/latest/UserGuide/index.html?AccessPolicyLanguage.html" target="_blank">The Access Policy Language</a> in <i>Using AWS Identity and Access Management</i>. The maximum size of an access policy document is 100 KB.</p> <p>Example: <code>{"Statement": [{"Effect":"Allow", "Action": "*", "Resource": "arn:aws:cs:us-east-1:1234567890:search/movies", "Condition": { "IpAddress": { "aws:SourceIp": ["203.0.113.1/32"] } }}, {"Effect":"Allow", "Action": "*", "Resource": "arn:aws:cs:us-east-1:1234567890:documents/movies", "Condition": { "IpAddress": { "aws:SourceIp": ["203.0.113.1/32"] } }} ] }</code></p>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_773839 = formData.getOrDefault("DomainName")
  valid_773839 = validateParameter(valid_773839, JString, required = true,
                                 default = nil)
  if valid_773839 != nil:
    section.add "DomainName", valid_773839
  var valid_773840 = formData.getOrDefault("AccessPolicies")
  valid_773840 = validateParameter(valid_773840, JString, required = true,
                                 default = nil)
  if valid_773840 != nil:
    section.add "AccessPolicies", valid_773840
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773841: Call_PostUpdateServiceAccessPolicies_773827;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Configures the policies that control access to the domain's document and search services. The maximum size of an access policy document is 100 KB.
  ## 
  let valid = call_773841.validator(path, query, header, formData, body)
  let scheme = call_773841.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773841.url(scheme.get, call_773841.host, call_773841.base,
                         call_773841.route, valid.getOrDefault("path"))
  result = hook(call_773841, url, valid)

proc call*(call_773842: Call_PostUpdateServiceAccessPolicies_773827;
          DomainName: string; AccessPolicies: string;
          Action: string = "UpdateServiceAccessPolicies";
          Version: string = "2011-02-01"): Recallable =
  ## postUpdateServiceAccessPolicies
  ## Configures the policies that control access to the domain's document and search services. The maximum size of an access policy document is 100 KB.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   AccessPolicies: string (required)
  ##                 : <p>An IAM access policy as described in <a 
  ## href="http://docs.aws.amazon.com/IAM/latest/UserGuide/index.html?AccessPolicyLanguage.html" target="_blank">The Access Policy Language</a> in <i>Using AWS Identity and Access Management</i>. The maximum size of an access policy document is 100 KB.</p> <p>Example: <code>{"Statement": [{"Effect":"Allow", "Action": "*", "Resource": "arn:aws:cs:us-east-1:1234567890:search/movies", "Condition": { "IpAddress": { "aws:SourceIp": ["203.0.113.1/32"] } }}, {"Effect":"Allow", "Action": "*", "Resource": "arn:aws:cs:us-east-1:1234567890:documents/movies", "Condition": { "IpAddress": { "aws:SourceIp": ["203.0.113.1/32"] } }} ] }</code></p>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773843 = newJObject()
  var formData_773844 = newJObject()
  add(formData_773844, "DomainName", newJString(DomainName))
  add(formData_773844, "AccessPolicies", newJString(AccessPolicies))
  add(query_773843, "Action", newJString(Action))
  add(query_773843, "Version", newJString(Version))
  result = call_773842.call(nil, query_773843, nil, formData_773844, nil)

var postUpdateServiceAccessPolicies* = Call_PostUpdateServiceAccessPolicies_773827(
    name: "postUpdateServiceAccessPolicies", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateServiceAccessPolicies",
    validator: validate_PostUpdateServiceAccessPolicies_773828, base: "/",
    url: url_PostUpdateServiceAccessPolicies_773829,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateServiceAccessPolicies_773810 = ref object of OpenApiRestCall_772597
proc url_GetUpdateServiceAccessPolicies_773812(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetUpdateServiceAccessPolicies_773811(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures the policies that control access to the domain's document and search services. The maximum size of an access policy document is 100 KB.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   AccessPolicies: JString (required)
  ##                 : <p>An IAM access policy as described in <a 
  ## href="http://docs.aws.amazon.com/IAM/latest/UserGuide/index.html?AccessPolicyLanguage.html" target="_blank">The Access Policy Language</a> in <i>Using AWS Identity and Access Management</i>. The maximum size of an access policy document is 100 KB.</p> <p>Example: <code>{"Statement": [{"Effect":"Allow", "Action": "*", "Resource": "arn:aws:cs:us-east-1:1234567890:search/movies", "Condition": { "IpAddress": { "aws:SourceIp": ["203.0.113.1/32"] } }}, {"Effect":"Allow", "Action": "*", "Resource": "arn:aws:cs:us-east-1:1234567890:documents/movies", "Condition": { "IpAddress": { "aws:SourceIp": ["203.0.113.1/32"] } }} ] }</code></p>
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773813 = query.getOrDefault("Action")
  valid_773813 = validateParameter(valid_773813, JString, required = true, default = newJString(
      "UpdateServiceAccessPolicies"))
  if valid_773813 != nil:
    section.add "Action", valid_773813
  var valid_773814 = query.getOrDefault("AccessPolicies")
  valid_773814 = validateParameter(valid_773814, JString, required = true,
                                 default = nil)
  if valid_773814 != nil:
    section.add "AccessPolicies", valid_773814
  var valid_773815 = query.getOrDefault("DomainName")
  valid_773815 = validateParameter(valid_773815, JString, required = true,
                                 default = nil)
  if valid_773815 != nil:
    section.add "DomainName", valid_773815
  var valid_773816 = query.getOrDefault("Version")
  valid_773816 = validateParameter(valid_773816, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_773816 != nil:
    section.add "Version", valid_773816
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773817 = header.getOrDefault("X-Amz-Date")
  valid_773817 = validateParameter(valid_773817, JString, required = false,
                                 default = nil)
  if valid_773817 != nil:
    section.add "X-Amz-Date", valid_773817
  var valid_773818 = header.getOrDefault("X-Amz-Security-Token")
  valid_773818 = validateParameter(valid_773818, JString, required = false,
                                 default = nil)
  if valid_773818 != nil:
    section.add "X-Amz-Security-Token", valid_773818
  var valid_773819 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773819 = validateParameter(valid_773819, JString, required = false,
                                 default = nil)
  if valid_773819 != nil:
    section.add "X-Amz-Content-Sha256", valid_773819
  var valid_773820 = header.getOrDefault("X-Amz-Algorithm")
  valid_773820 = validateParameter(valid_773820, JString, required = false,
                                 default = nil)
  if valid_773820 != nil:
    section.add "X-Amz-Algorithm", valid_773820
  var valid_773821 = header.getOrDefault("X-Amz-Signature")
  valid_773821 = validateParameter(valid_773821, JString, required = false,
                                 default = nil)
  if valid_773821 != nil:
    section.add "X-Amz-Signature", valid_773821
  var valid_773822 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773822 = validateParameter(valid_773822, JString, required = false,
                                 default = nil)
  if valid_773822 != nil:
    section.add "X-Amz-SignedHeaders", valid_773822
  var valid_773823 = header.getOrDefault("X-Amz-Credential")
  valid_773823 = validateParameter(valid_773823, JString, required = false,
                                 default = nil)
  if valid_773823 != nil:
    section.add "X-Amz-Credential", valid_773823
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773824: Call_GetUpdateServiceAccessPolicies_773810; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the policies that control access to the domain's document and search services. The maximum size of an access policy document is 100 KB.
  ## 
  let valid = call_773824.validator(path, query, header, formData, body)
  let scheme = call_773824.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773824.url(scheme.get, call_773824.host, call_773824.base,
                         call_773824.route, valid.getOrDefault("path"))
  result = hook(call_773824, url, valid)

proc call*(call_773825: Call_GetUpdateServiceAccessPolicies_773810;
          AccessPolicies: string; DomainName: string;
          Action: string = "UpdateServiceAccessPolicies";
          Version: string = "2011-02-01"): Recallable =
  ## getUpdateServiceAccessPolicies
  ## Configures the policies that control access to the domain's document and search services. The maximum size of an access policy document is 100 KB.
  ##   Action: string (required)
  ##   AccessPolicies: string (required)
  ##                 : <p>An IAM access policy as described in <a 
  ## href="http://docs.aws.amazon.com/IAM/latest/UserGuide/index.html?AccessPolicyLanguage.html" target="_blank">The Access Policy Language</a> in <i>Using AWS Identity and Access Management</i>. The maximum size of an access policy document is 100 KB.</p> <p>Example: <code>{"Statement": [{"Effect":"Allow", "Action": "*", "Resource": "arn:aws:cs:us-east-1:1234567890:search/movies", "Condition": { "IpAddress": { "aws:SourceIp": ["203.0.113.1/32"] } }}, {"Effect":"Allow", "Action": "*", "Resource": "arn:aws:cs:us-east-1:1234567890:documents/movies", "Condition": { "IpAddress": { "aws:SourceIp": ["203.0.113.1/32"] } }} ] }</code></p>
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_773826 = newJObject()
  add(query_773826, "Action", newJString(Action))
  add(query_773826, "AccessPolicies", newJString(AccessPolicies))
  add(query_773826, "DomainName", newJString(DomainName))
  add(query_773826, "Version", newJString(Version))
  result = call_773825.call(nil, query_773826, nil, nil, nil)

var getUpdateServiceAccessPolicies* = Call_GetUpdateServiceAccessPolicies_773810(
    name: "getUpdateServiceAccessPolicies", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateServiceAccessPolicies",
    validator: validate_GetUpdateServiceAccessPolicies_773811, base: "/",
    url: url_GetUpdateServiceAccessPolicies_773812,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateStemmingOptions_773862 = ref object of OpenApiRestCall_772597
proc url_PostUpdateStemmingOptions_773864(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostUpdateStemmingOptions_773863(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures a stemming dictionary for the search domain. The stemming dictionary is used during indexing and when processing search requests. The maximum size of the stemming dictionary is 500 KB.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773865 = query.getOrDefault("Action")
  valid_773865 = validateParameter(valid_773865, JString, required = true,
                                 default = newJString("UpdateStemmingOptions"))
  if valid_773865 != nil:
    section.add "Action", valid_773865
  var valid_773866 = query.getOrDefault("Version")
  valid_773866 = validateParameter(valid_773866, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_773866 != nil:
    section.add "Version", valid_773866
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773867 = header.getOrDefault("X-Amz-Date")
  valid_773867 = validateParameter(valid_773867, JString, required = false,
                                 default = nil)
  if valid_773867 != nil:
    section.add "X-Amz-Date", valid_773867
  var valid_773868 = header.getOrDefault("X-Amz-Security-Token")
  valid_773868 = validateParameter(valid_773868, JString, required = false,
                                 default = nil)
  if valid_773868 != nil:
    section.add "X-Amz-Security-Token", valid_773868
  var valid_773869 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773869 = validateParameter(valid_773869, JString, required = false,
                                 default = nil)
  if valid_773869 != nil:
    section.add "X-Amz-Content-Sha256", valid_773869
  var valid_773870 = header.getOrDefault("X-Amz-Algorithm")
  valid_773870 = validateParameter(valid_773870, JString, required = false,
                                 default = nil)
  if valid_773870 != nil:
    section.add "X-Amz-Algorithm", valid_773870
  var valid_773871 = header.getOrDefault("X-Amz-Signature")
  valid_773871 = validateParameter(valid_773871, JString, required = false,
                                 default = nil)
  if valid_773871 != nil:
    section.add "X-Amz-Signature", valid_773871
  var valid_773872 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773872 = validateParameter(valid_773872, JString, required = false,
                                 default = nil)
  if valid_773872 != nil:
    section.add "X-Amz-SignedHeaders", valid_773872
  var valid_773873 = header.getOrDefault("X-Amz-Credential")
  valid_773873 = validateParameter(valid_773873, JString, required = false,
                                 default = nil)
  if valid_773873 != nil:
    section.add "X-Amz-Credential", valid_773873
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Stems: JString (required)
  ##        : Maps terms to their stems, serialized as a JSON document. The document has a single object with one property "stems" whose value is an object mapping terms to their stems. The maximum size of a stemming document is 500 KB. Example: <code>{ "stems": {"people": "person", "walking": "walk"} }</code>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_773874 = formData.getOrDefault("DomainName")
  valid_773874 = validateParameter(valid_773874, JString, required = true,
                                 default = nil)
  if valid_773874 != nil:
    section.add "DomainName", valid_773874
  var valid_773875 = formData.getOrDefault("Stems")
  valid_773875 = validateParameter(valid_773875, JString, required = true,
                                 default = nil)
  if valid_773875 != nil:
    section.add "Stems", valid_773875
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773876: Call_PostUpdateStemmingOptions_773862; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a stemming dictionary for the search domain. The stemming dictionary is used during indexing and when processing search requests. The maximum size of the stemming dictionary is 500 KB.
  ## 
  let valid = call_773876.validator(path, query, header, formData, body)
  let scheme = call_773876.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773876.url(scheme.get, call_773876.host, call_773876.base,
                         call_773876.route, valid.getOrDefault("path"))
  result = hook(call_773876, url, valid)

proc call*(call_773877: Call_PostUpdateStemmingOptions_773862; DomainName: string;
          Stems: string; Action: string = "UpdateStemmingOptions";
          Version: string = "2011-02-01"): Recallable =
  ## postUpdateStemmingOptions
  ## Configures a stemming dictionary for the search domain. The stemming dictionary is used during indexing and when processing search requests. The maximum size of the stemming dictionary is 500 KB.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Stems: string (required)
  ##        : Maps terms to their stems, serialized as a JSON document. The document has a single object with one property "stems" whose value is an object mapping terms to their stems. The maximum size of a stemming document is 500 KB. Example: <code>{ "stems": {"people": "person", "walking": "walk"} }</code>
  ##   Version: string (required)
  var query_773878 = newJObject()
  var formData_773879 = newJObject()
  add(formData_773879, "DomainName", newJString(DomainName))
  add(query_773878, "Action", newJString(Action))
  add(formData_773879, "Stems", newJString(Stems))
  add(query_773878, "Version", newJString(Version))
  result = call_773877.call(nil, query_773878, nil, formData_773879, nil)

var postUpdateStemmingOptions* = Call_PostUpdateStemmingOptions_773862(
    name: "postUpdateStemmingOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateStemmingOptions",
    validator: validate_PostUpdateStemmingOptions_773863, base: "/",
    url: url_PostUpdateStemmingOptions_773864,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateStemmingOptions_773845 = ref object of OpenApiRestCall_772597
proc url_GetUpdateStemmingOptions_773847(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetUpdateStemmingOptions_773846(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures a stemming dictionary for the search domain. The stemming dictionary is used during indexing and when processing search requests. The maximum size of the stemming dictionary is 500 KB.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Stems: JString (required)
  ##        : Maps terms to their stems, serialized as a JSON document. The document has a single object with one property "stems" whose value is an object mapping terms to their stems. The maximum size of a stemming document is 500 KB. Example: <code>{ "stems": {"people": "person", "walking": "walk"} }</code>
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773848 = query.getOrDefault("Action")
  valid_773848 = validateParameter(valid_773848, JString, required = true,
                                 default = newJString("UpdateStemmingOptions"))
  if valid_773848 != nil:
    section.add "Action", valid_773848
  var valid_773849 = query.getOrDefault("Stems")
  valid_773849 = validateParameter(valid_773849, JString, required = true,
                                 default = nil)
  if valid_773849 != nil:
    section.add "Stems", valid_773849
  var valid_773850 = query.getOrDefault("DomainName")
  valid_773850 = validateParameter(valid_773850, JString, required = true,
                                 default = nil)
  if valid_773850 != nil:
    section.add "DomainName", valid_773850
  var valid_773851 = query.getOrDefault("Version")
  valid_773851 = validateParameter(valid_773851, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_773851 != nil:
    section.add "Version", valid_773851
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773852 = header.getOrDefault("X-Amz-Date")
  valid_773852 = validateParameter(valid_773852, JString, required = false,
                                 default = nil)
  if valid_773852 != nil:
    section.add "X-Amz-Date", valid_773852
  var valid_773853 = header.getOrDefault("X-Amz-Security-Token")
  valid_773853 = validateParameter(valid_773853, JString, required = false,
                                 default = nil)
  if valid_773853 != nil:
    section.add "X-Amz-Security-Token", valid_773853
  var valid_773854 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773854 = validateParameter(valid_773854, JString, required = false,
                                 default = nil)
  if valid_773854 != nil:
    section.add "X-Amz-Content-Sha256", valid_773854
  var valid_773855 = header.getOrDefault("X-Amz-Algorithm")
  valid_773855 = validateParameter(valid_773855, JString, required = false,
                                 default = nil)
  if valid_773855 != nil:
    section.add "X-Amz-Algorithm", valid_773855
  var valid_773856 = header.getOrDefault("X-Amz-Signature")
  valid_773856 = validateParameter(valid_773856, JString, required = false,
                                 default = nil)
  if valid_773856 != nil:
    section.add "X-Amz-Signature", valid_773856
  var valid_773857 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773857 = validateParameter(valid_773857, JString, required = false,
                                 default = nil)
  if valid_773857 != nil:
    section.add "X-Amz-SignedHeaders", valid_773857
  var valid_773858 = header.getOrDefault("X-Amz-Credential")
  valid_773858 = validateParameter(valid_773858, JString, required = false,
                                 default = nil)
  if valid_773858 != nil:
    section.add "X-Amz-Credential", valid_773858
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773859: Call_GetUpdateStemmingOptions_773845; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a stemming dictionary for the search domain. The stemming dictionary is used during indexing and when processing search requests. The maximum size of the stemming dictionary is 500 KB.
  ## 
  let valid = call_773859.validator(path, query, header, formData, body)
  let scheme = call_773859.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773859.url(scheme.get, call_773859.host, call_773859.base,
                         call_773859.route, valid.getOrDefault("path"))
  result = hook(call_773859, url, valid)

proc call*(call_773860: Call_GetUpdateStemmingOptions_773845; Stems: string;
          DomainName: string; Action: string = "UpdateStemmingOptions";
          Version: string = "2011-02-01"): Recallable =
  ## getUpdateStemmingOptions
  ## Configures a stemming dictionary for the search domain. The stemming dictionary is used during indexing and when processing search requests. The maximum size of the stemming dictionary is 500 KB.
  ##   Action: string (required)
  ##   Stems: string (required)
  ##        : Maps terms to their stems, serialized as a JSON document. The document has a single object with one property "stems" whose value is an object mapping terms to their stems. The maximum size of a stemming document is 500 KB. Example: <code>{ "stems": {"people": "person", "walking": "walk"} }</code>
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_773861 = newJObject()
  add(query_773861, "Action", newJString(Action))
  add(query_773861, "Stems", newJString(Stems))
  add(query_773861, "DomainName", newJString(DomainName))
  add(query_773861, "Version", newJString(Version))
  result = call_773860.call(nil, query_773861, nil, nil, nil)

var getUpdateStemmingOptions* = Call_GetUpdateStemmingOptions_773845(
    name: "getUpdateStemmingOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateStemmingOptions",
    validator: validate_GetUpdateStemmingOptions_773846, base: "/",
    url: url_GetUpdateStemmingOptions_773847, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateStopwordOptions_773897 = ref object of OpenApiRestCall_772597
proc url_PostUpdateStopwordOptions_773899(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostUpdateStopwordOptions_773898(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures stopwords for the search domain. Stopwords are used during indexing and when processing search requests. The maximum size of the stopwords dictionary is 10 KB.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773900 = query.getOrDefault("Action")
  valid_773900 = validateParameter(valid_773900, JString, required = true,
                                 default = newJString("UpdateStopwordOptions"))
  if valid_773900 != nil:
    section.add "Action", valid_773900
  var valid_773901 = query.getOrDefault("Version")
  valid_773901 = validateParameter(valid_773901, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_773901 != nil:
    section.add "Version", valid_773901
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773902 = header.getOrDefault("X-Amz-Date")
  valid_773902 = validateParameter(valid_773902, JString, required = false,
                                 default = nil)
  if valid_773902 != nil:
    section.add "X-Amz-Date", valid_773902
  var valid_773903 = header.getOrDefault("X-Amz-Security-Token")
  valid_773903 = validateParameter(valid_773903, JString, required = false,
                                 default = nil)
  if valid_773903 != nil:
    section.add "X-Amz-Security-Token", valid_773903
  var valid_773904 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773904 = validateParameter(valid_773904, JString, required = false,
                                 default = nil)
  if valid_773904 != nil:
    section.add "X-Amz-Content-Sha256", valid_773904
  var valid_773905 = header.getOrDefault("X-Amz-Algorithm")
  valid_773905 = validateParameter(valid_773905, JString, required = false,
                                 default = nil)
  if valid_773905 != nil:
    section.add "X-Amz-Algorithm", valid_773905
  var valid_773906 = header.getOrDefault("X-Amz-Signature")
  valid_773906 = validateParameter(valid_773906, JString, required = false,
                                 default = nil)
  if valid_773906 != nil:
    section.add "X-Amz-Signature", valid_773906
  var valid_773907 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773907 = validateParameter(valid_773907, JString, required = false,
                                 default = nil)
  if valid_773907 != nil:
    section.add "X-Amz-SignedHeaders", valid_773907
  var valid_773908 = header.getOrDefault("X-Amz-Credential")
  valid_773908 = validateParameter(valid_773908, JString, required = false,
                                 default = nil)
  if valid_773908 != nil:
    section.add "X-Amz-Credential", valid_773908
  result.add "header", section
  ## parameters in `formData` object:
  ##   Stopwords: JString (required)
  ##            : Lists stopwords serialized as a JSON document. The document has a single object with one property "stopwords" whose value is an array of strings. The maximum size of a stopwords document is 10 KB. Example: <code>{ "stopwords": ["a", "an", "the", "of"] }</code>
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Stopwords` field"
  var valid_773909 = formData.getOrDefault("Stopwords")
  valid_773909 = validateParameter(valid_773909, JString, required = true,
                                 default = nil)
  if valid_773909 != nil:
    section.add "Stopwords", valid_773909
  var valid_773910 = formData.getOrDefault("DomainName")
  valid_773910 = validateParameter(valid_773910, JString, required = true,
                                 default = nil)
  if valid_773910 != nil:
    section.add "DomainName", valid_773910
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773911: Call_PostUpdateStopwordOptions_773897; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures stopwords for the search domain. Stopwords are used during indexing and when processing search requests. The maximum size of the stopwords dictionary is 10 KB.
  ## 
  let valid = call_773911.validator(path, query, header, formData, body)
  let scheme = call_773911.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773911.url(scheme.get, call_773911.host, call_773911.base,
                         call_773911.route, valid.getOrDefault("path"))
  result = hook(call_773911, url, valid)

proc call*(call_773912: Call_PostUpdateStopwordOptions_773897; Stopwords: string;
          DomainName: string; Action: string = "UpdateStopwordOptions";
          Version: string = "2011-02-01"): Recallable =
  ## postUpdateStopwordOptions
  ## Configures stopwords for the search domain. Stopwords are used during indexing and when processing search requests. The maximum size of the stopwords dictionary is 10 KB.
  ##   Stopwords: string (required)
  ##            : Lists stopwords serialized as a JSON document. The document has a single object with one property "stopwords" whose value is an array of strings. The maximum size of a stopwords document is 10 KB. Example: <code>{ "stopwords": ["a", "an", "the", "of"] }</code>
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773913 = newJObject()
  var formData_773914 = newJObject()
  add(formData_773914, "Stopwords", newJString(Stopwords))
  add(formData_773914, "DomainName", newJString(DomainName))
  add(query_773913, "Action", newJString(Action))
  add(query_773913, "Version", newJString(Version))
  result = call_773912.call(nil, query_773913, nil, formData_773914, nil)

var postUpdateStopwordOptions* = Call_PostUpdateStopwordOptions_773897(
    name: "postUpdateStopwordOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateStopwordOptions",
    validator: validate_PostUpdateStopwordOptions_773898, base: "/",
    url: url_PostUpdateStopwordOptions_773899,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateStopwordOptions_773880 = ref object of OpenApiRestCall_772597
proc url_GetUpdateStopwordOptions_773882(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetUpdateStopwordOptions_773881(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures stopwords for the search domain. Stopwords are used during indexing and when processing search requests. The maximum size of the stopwords dictionary is 10 KB.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Stopwords: JString (required)
  ##            : Lists stopwords serialized as a JSON document. The document has a single object with one property "stopwords" whose value is an array of strings. The maximum size of a stopwords document is 10 KB. Example: <code>{ "stopwords": ["a", "an", "the", "of"] }</code>
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773883 = query.getOrDefault("Action")
  valid_773883 = validateParameter(valid_773883, JString, required = true,
                                 default = newJString("UpdateStopwordOptions"))
  if valid_773883 != nil:
    section.add "Action", valid_773883
  var valid_773884 = query.getOrDefault("Stopwords")
  valid_773884 = validateParameter(valid_773884, JString, required = true,
                                 default = nil)
  if valid_773884 != nil:
    section.add "Stopwords", valid_773884
  var valid_773885 = query.getOrDefault("DomainName")
  valid_773885 = validateParameter(valid_773885, JString, required = true,
                                 default = nil)
  if valid_773885 != nil:
    section.add "DomainName", valid_773885
  var valid_773886 = query.getOrDefault("Version")
  valid_773886 = validateParameter(valid_773886, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_773886 != nil:
    section.add "Version", valid_773886
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773887 = header.getOrDefault("X-Amz-Date")
  valid_773887 = validateParameter(valid_773887, JString, required = false,
                                 default = nil)
  if valid_773887 != nil:
    section.add "X-Amz-Date", valid_773887
  var valid_773888 = header.getOrDefault("X-Amz-Security-Token")
  valid_773888 = validateParameter(valid_773888, JString, required = false,
                                 default = nil)
  if valid_773888 != nil:
    section.add "X-Amz-Security-Token", valid_773888
  var valid_773889 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773889 = validateParameter(valid_773889, JString, required = false,
                                 default = nil)
  if valid_773889 != nil:
    section.add "X-Amz-Content-Sha256", valid_773889
  var valid_773890 = header.getOrDefault("X-Amz-Algorithm")
  valid_773890 = validateParameter(valid_773890, JString, required = false,
                                 default = nil)
  if valid_773890 != nil:
    section.add "X-Amz-Algorithm", valid_773890
  var valid_773891 = header.getOrDefault("X-Amz-Signature")
  valid_773891 = validateParameter(valid_773891, JString, required = false,
                                 default = nil)
  if valid_773891 != nil:
    section.add "X-Amz-Signature", valid_773891
  var valid_773892 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773892 = validateParameter(valid_773892, JString, required = false,
                                 default = nil)
  if valid_773892 != nil:
    section.add "X-Amz-SignedHeaders", valid_773892
  var valid_773893 = header.getOrDefault("X-Amz-Credential")
  valid_773893 = validateParameter(valid_773893, JString, required = false,
                                 default = nil)
  if valid_773893 != nil:
    section.add "X-Amz-Credential", valid_773893
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773894: Call_GetUpdateStopwordOptions_773880; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures stopwords for the search domain. Stopwords are used during indexing and when processing search requests. The maximum size of the stopwords dictionary is 10 KB.
  ## 
  let valid = call_773894.validator(path, query, header, formData, body)
  let scheme = call_773894.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773894.url(scheme.get, call_773894.host, call_773894.base,
                         call_773894.route, valid.getOrDefault("path"))
  result = hook(call_773894, url, valid)

proc call*(call_773895: Call_GetUpdateStopwordOptions_773880; Stopwords: string;
          DomainName: string; Action: string = "UpdateStopwordOptions";
          Version: string = "2011-02-01"): Recallable =
  ## getUpdateStopwordOptions
  ## Configures stopwords for the search domain. Stopwords are used during indexing and when processing search requests. The maximum size of the stopwords dictionary is 10 KB.
  ##   Action: string (required)
  ##   Stopwords: string (required)
  ##            : Lists stopwords serialized as a JSON document. The document has a single object with one property "stopwords" whose value is an array of strings. The maximum size of a stopwords document is 10 KB. Example: <code>{ "stopwords": ["a", "an", "the", "of"] }</code>
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_773896 = newJObject()
  add(query_773896, "Action", newJString(Action))
  add(query_773896, "Stopwords", newJString(Stopwords))
  add(query_773896, "DomainName", newJString(DomainName))
  add(query_773896, "Version", newJString(Version))
  result = call_773895.call(nil, query_773896, nil, nil, nil)

var getUpdateStopwordOptions* = Call_GetUpdateStopwordOptions_773880(
    name: "getUpdateStopwordOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateStopwordOptions",
    validator: validate_GetUpdateStopwordOptions_773881, base: "/",
    url: url_GetUpdateStopwordOptions_773882, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateSynonymOptions_773932 = ref object of OpenApiRestCall_772597
proc url_PostUpdateSynonymOptions_773934(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostUpdateSynonymOptions_773933(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures a synonym dictionary for the search domain. The synonym dictionary is used during indexing to configure mappings for terms that occur in text fields. The maximum size of the synonym dictionary is 100 KB. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773935 = query.getOrDefault("Action")
  valid_773935 = validateParameter(valid_773935, JString, required = true,
                                 default = newJString("UpdateSynonymOptions"))
  if valid_773935 != nil:
    section.add "Action", valid_773935
  var valid_773936 = query.getOrDefault("Version")
  valid_773936 = validateParameter(valid_773936, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_773936 != nil:
    section.add "Version", valid_773936
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773937 = header.getOrDefault("X-Amz-Date")
  valid_773937 = validateParameter(valid_773937, JString, required = false,
                                 default = nil)
  if valid_773937 != nil:
    section.add "X-Amz-Date", valid_773937
  var valid_773938 = header.getOrDefault("X-Amz-Security-Token")
  valid_773938 = validateParameter(valid_773938, JString, required = false,
                                 default = nil)
  if valid_773938 != nil:
    section.add "X-Amz-Security-Token", valid_773938
  var valid_773939 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773939 = validateParameter(valid_773939, JString, required = false,
                                 default = nil)
  if valid_773939 != nil:
    section.add "X-Amz-Content-Sha256", valid_773939
  var valid_773940 = header.getOrDefault("X-Amz-Algorithm")
  valid_773940 = validateParameter(valid_773940, JString, required = false,
                                 default = nil)
  if valid_773940 != nil:
    section.add "X-Amz-Algorithm", valid_773940
  var valid_773941 = header.getOrDefault("X-Amz-Signature")
  valid_773941 = validateParameter(valid_773941, JString, required = false,
                                 default = nil)
  if valid_773941 != nil:
    section.add "X-Amz-Signature", valid_773941
  var valid_773942 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773942 = validateParameter(valid_773942, JString, required = false,
                                 default = nil)
  if valid_773942 != nil:
    section.add "X-Amz-SignedHeaders", valid_773942
  var valid_773943 = header.getOrDefault("X-Amz-Credential")
  valid_773943 = validateParameter(valid_773943, JString, required = false,
                                 default = nil)
  if valid_773943 != nil:
    section.add "X-Amz-Credential", valid_773943
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Synonyms: JString (required)
  ##           : Maps terms to their synonyms, serialized as a JSON document. The document has a single object with one property "synonyms" whose value is an object mapping terms to their synonyms. Each synonym is a simple string or an array of strings. The maximum size of a stopwords document is 100 KB. Example: <code>{ "synonyms": {"cat": ["feline", "kitten"], "puppy": "dog"} }</code>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_773944 = formData.getOrDefault("DomainName")
  valid_773944 = validateParameter(valid_773944, JString, required = true,
                                 default = nil)
  if valid_773944 != nil:
    section.add "DomainName", valid_773944
  var valid_773945 = formData.getOrDefault("Synonyms")
  valid_773945 = validateParameter(valid_773945, JString, required = true,
                                 default = nil)
  if valid_773945 != nil:
    section.add "Synonyms", valid_773945
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773946: Call_PostUpdateSynonymOptions_773932; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a synonym dictionary for the search domain. The synonym dictionary is used during indexing to configure mappings for terms that occur in text fields. The maximum size of the synonym dictionary is 100 KB. 
  ## 
  let valid = call_773946.validator(path, query, header, formData, body)
  let scheme = call_773946.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773946.url(scheme.get, call_773946.host, call_773946.base,
                         call_773946.route, valid.getOrDefault("path"))
  result = hook(call_773946, url, valid)

proc call*(call_773947: Call_PostUpdateSynonymOptions_773932; DomainName: string;
          Synonyms: string; Action: string = "UpdateSynonymOptions";
          Version: string = "2011-02-01"): Recallable =
  ## postUpdateSynonymOptions
  ## Configures a synonym dictionary for the search domain. The synonym dictionary is used during indexing to configure mappings for terms that occur in text fields. The maximum size of the synonym dictionary is 100 KB. 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Synonyms: string (required)
  ##           : Maps terms to their synonyms, serialized as a JSON document. The document has a single object with one property "synonyms" whose value is an object mapping terms to their synonyms. Each synonym is a simple string or an array of strings. The maximum size of a stopwords document is 100 KB. Example: <code>{ "synonyms": {"cat": ["feline", "kitten"], "puppy": "dog"} }</code>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_773948 = newJObject()
  var formData_773949 = newJObject()
  add(formData_773949, "DomainName", newJString(DomainName))
  add(formData_773949, "Synonyms", newJString(Synonyms))
  add(query_773948, "Action", newJString(Action))
  add(query_773948, "Version", newJString(Version))
  result = call_773947.call(nil, query_773948, nil, formData_773949, nil)

var postUpdateSynonymOptions* = Call_PostUpdateSynonymOptions_773932(
    name: "postUpdateSynonymOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateSynonymOptions",
    validator: validate_PostUpdateSynonymOptions_773933, base: "/",
    url: url_PostUpdateSynonymOptions_773934, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateSynonymOptions_773915 = ref object of OpenApiRestCall_772597
proc url_GetUpdateSynonymOptions_773917(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetUpdateSynonymOptions_773916(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures a synonym dictionary for the search domain. The synonym dictionary is used during indexing to configure mappings for terms that occur in text fields. The maximum size of the synonym dictionary is 100 KB. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Action: JString (required)
  ##   Synonyms: JString (required)
  ##           : Maps terms to their synonyms, serialized as a JSON document. The document has a single object with one property "synonyms" whose value is an object mapping terms to their synonyms. Each synonym is a simple string or an array of strings. The maximum size of a stopwords document is 100 KB. Example: <code>{ "synonyms": {"cat": ["feline", "kitten"], "puppy": "dog"} }</code>
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_773918 = query.getOrDefault("Action")
  valid_773918 = validateParameter(valid_773918, JString, required = true,
                                 default = newJString("UpdateSynonymOptions"))
  if valid_773918 != nil:
    section.add "Action", valid_773918
  var valid_773919 = query.getOrDefault("Synonyms")
  valid_773919 = validateParameter(valid_773919, JString, required = true,
                                 default = nil)
  if valid_773919 != nil:
    section.add "Synonyms", valid_773919
  var valid_773920 = query.getOrDefault("DomainName")
  valid_773920 = validateParameter(valid_773920, JString, required = true,
                                 default = nil)
  if valid_773920 != nil:
    section.add "DomainName", valid_773920
  var valid_773921 = query.getOrDefault("Version")
  valid_773921 = validateParameter(valid_773921, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_773921 != nil:
    section.add "Version", valid_773921
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_773922 = header.getOrDefault("X-Amz-Date")
  valid_773922 = validateParameter(valid_773922, JString, required = false,
                                 default = nil)
  if valid_773922 != nil:
    section.add "X-Amz-Date", valid_773922
  var valid_773923 = header.getOrDefault("X-Amz-Security-Token")
  valid_773923 = validateParameter(valid_773923, JString, required = false,
                                 default = nil)
  if valid_773923 != nil:
    section.add "X-Amz-Security-Token", valid_773923
  var valid_773924 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_773924 = validateParameter(valid_773924, JString, required = false,
                                 default = nil)
  if valid_773924 != nil:
    section.add "X-Amz-Content-Sha256", valid_773924
  var valid_773925 = header.getOrDefault("X-Amz-Algorithm")
  valid_773925 = validateParameter(valid_773925, JString, required = false,
                                 default = nil)
  if valid_773925 != nil:
    section.add "X-Amz-Algorithm", valid_773925
  var valid_773926 = header.getOrDefault("X-Amz-Signature")
  valid_773926 = validateParameter(valid_773926, JString, required = false,
                                 default = nil)
  if valid_773926 != nil:
    section.add "X-Amz-Signature", valid_773926
  var valid_773927 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_773927 = validateParameter(valid_773927, JString, required = false,
                                 default = nil)
  if valid_773927 != nil:
    section.add "X-Amz-SignedHeaders", valid_773927
  var valid_773928 = header.getOrDefault("X-Amz-Credential")
  valid_773928 = validateParameter(valid_773928, JString, required = false,
                                 default = nil)
  if valid_773928 != nil:
    section.add "X-Amz-Credential", valid_773928
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_773929: Call_GetUpdateSynonymOptions_773915; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a synonym dictionary for the search domain. The synonym dictionary is used during indexing to configure mappings for terms that occur in text fields. The maximum size of the synonym dictionary is 100 KB. 
  ## 
  let valid = call_773929.validator(path, query, header, formData, body)
  let scheme = call_773929.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_773929.url(scheme.get, call_773929.host, call_773929.base,
                         call_773929.route, valid.getOrDefault("path"))
  result = hook(call_773929, url, valid)

proc call*(call_773930: Call_GetUpdateSynonymOptions_773915; Synonyms: string;
          DomainName: string; Action: string = "UpdateSynonymOptions";
          Version: string = "2011-02-01"): Recallable =
  ## getUpdateSynonymOptions
  ## Configures a synonym dictionary for the search domain. The synonym dictionary is used during indexing to configure mappings for terms that occur in text fields. The maximum size of the synonym dictionary is 100 KB. 
  ##   Action: string (required)
  ##   Synonyms: string (required)
  ##           : Maps terms to their synonyms, serialized as a JSON document. The document has a single object with one property "synonyms" whose value is an object mapping terms to their synonyms. Each synonym is a simple string or an array of strings. The maximum size of a stopwords document is 100 KB. Example: <code>{ "synonyms": {"cat": ["feline", "kitten"], "puppy": "dog"} }</code>
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_773931 = newJObject()
  add(query_773931, "Action", newJString(Action))
  add(query_773931, "Synonyms", newJString(Synonyms))
  add(query_773931, "DomainName", newJString(DomainName))
  add(query_773931, "Version", newJString(Version))
  result = call_773930.call(nil, query_773931, nil, nil, nil)

var getUpdateSynonymOptions* = Call_GetUpdateSynonymOptions_773915(
    name: "getUpdateSynonymOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateSynonymOptions",
    validator: validate_GetUpdateSynonymOptions_773916, base: "/",
    url: url_GetUpdateSynonymOptions_773917, schemes: {Scheme.Https, Scheme.Http})
proc sign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", "")
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", "")
    region = os.getEnv("AWS_REGION", "")
  assert secret != "", "need secret key in env"
  assert access != "", "need access key in env"
  assert region != "", "need region in env"
  var
    normal: PathNormal
    url = normalizeUrl(recall.url, query, normalize = normal)
    scheme = parseEnum[Scheme](url.scheme)
  assert scheme in awsServers, "unknown scheme `" & $scheme & "`"
  assert region in awsServers[scheme], "unknown region `" & region & "`"
  url.hostname = awsServers[scheme][region]
  case awsServiceName.toLowerAscii
  of "s3":
    normal = PathNormal.S3
  else:
    normal = PathNormal.Default
  recall.headers["Host"] = url.hostname
  recall.headers["X-Amz-Date"] = date
  let
    algo = SHA256
    scope = credentialScope(region = region, service = awsServiceName, date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers, recall.body,
                             normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date, region = region,
                                 service = awsServiceName, sts, digest = algo)
  var auth = $algo & " "
  auth &= "Credential=" & access / scope & ", "
  auth &= "SignedHeaders=" & recall.headers.signedHeaders & ", "
  auth &= "Signature=" & signature
  recall.headers["Authorization"] = auth
  echo recall.headers
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)
