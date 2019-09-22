
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

  OpenApiRestCall_602433 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_602433](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_602433): Option[Scheme] {.used.} =
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
  result = some(head & remainder.get)

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
  Call_PostCreateDomain_603041 = ref object of OpenApiRestCall_602433
proc url_PostCreateDomain_603043(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateDomain_603042(path: JsonNode; query: JsonNode;
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
  var valid_603044 = query.getOrDefault("Action")
  valid_603044 = validateParameter(valid_603044, JString, required = true,
                                 default = newJString("CreateDomain"))
  if valid_603044 != nil:
    section.add "Action", valid_603044
  var valid_603045 = query.getOrDefault("Version")
  valid_603045 = validateParameter(valid_603045, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_603045 != nil:
    section.add "Version", valid_603045
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
  var valid_603046 = header.getOrDefault("X-Amz-Date")
  valid_603046 = validateParameter(valid_603046, JString, required = false,
                                 default = nil)
  if valid_603046 != nil:
    section.add "X-Amz-Date", valid_603046
  var valid_603047 = header.getOrDefault("X-Amz-Security-Token")
  valid_603047 = validateParameter(valid_603047, JString, required = false,
                                 default = nil)
  if valid_603047 != nil:
    section.add "X-Amz-Security-Token", valid_603047
  var valid_603048 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603048 = validateParameter(valid_603048, JString, required = false,
                                 default = nil)
  if valid_603048 != nil:
    section.add "X-Amz-Content-Sha256", valid_603048
  var valid_603049 = header.getOrDefault("X-Amz-Algorithm")
  valid_603049 = validateParameter(valid_603049, JString, required = false,
                                 default = nil)
  if valid_603049 != nil:
    section.add "X-Amz-Algorithm", valid_603049
  var valid_603050 = header.getOrDefault("X-Amz-Signature")
  valid_603050 = validateParameter(valid_603050, JString, required = false,
                                 default = nil)
  if valid_603050 != nil:
    section.add "X-Amz-Signature", valid_603050
  var valid_603051 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603051 = validateParameter(valid_603051, JString, required = false,
                                 default = nil)
  if valid_603051 != nil:
    section.add "X-Amz-SignedHeaders", valid_603051
  var valid_603052 = header.getOrDefault("X-Amz-Credential")
  valid_603052 = validateParameter(valid_603052, JString, required = false,
                                 default = nil)
  if valid_603052 != nil:
    section.add "X-Amz-Credential", valid_603052
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_603053 = formData.getOrDefault("DomainName")
  valid_603053 = validateParameter(valid_603053, JString, required = true,
                                 default = nil)
  if valid_603053 != nil:
    section.add "DomainName", valid_603053
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603054: Call_PostCreateDomain_603041; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new search domain.
  ## 
  let valid = call_603054.validator(path, query, header, formData, body)
  let scheme = call_603054.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603054.url(scheme.get, call_603054.host, call_603054.base,
                         call_603054.route, valid.getOrDefault("path"))
  result = hook(call_603054, url, valid)

proc call*(call_603055: Call_PostCreateDomain_603041; DomainName: string;
          Action: string = "CreateDomain"; Version: string = "2011-02-01"): Recallable =
  ## postCreateDomain
  ## Creates a new search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603056 = newJObject()
  var formData_603057 = newJObject()
  add(formData_603057, "DomainName", newJString(DomainName))
  add(query_603056, "Action", newJString(Action))
  add(query_603056, "Version", newJString(Version))
  result = call_603055.call(nil, query_603056, nil, formData_603057, nil)

var postCreateDomain* = Call_PostCreateDomain_603041(name: "postCreateDomain",
    meth: HttpMethod.HttpPost, host: "cloudsearch.amazonaws.com",
    route: "/#Action=CreateDomain", validator: validate_PostCreateDomain_603042,
    base: "/", url: url_PostCreateDomain_603043,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDomain_602770 = ref object of OpenApiRestCall_602433
proc url_GetCreateDomain_602772(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateDomain_602771(path: JsonNode; query: JsonNode;
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
  var valid_602897 = query.getOrDefault("Action")
  valid_602897 = validateParameter(valid_602897, JString, required = true,
                                 default = newJString("CreateDomain"))
  if valid_602897 != nil:
    section.add "Action", valid_602897
  var valid_602898 = query.getOrDefault("DomainName")
  valid_602898 = validateParameter(valid_602898, JString, required = true,
                                 default = nil)
  if valid_602898 != nil:
    section.add "DomainName", valid_602898
  var valid_602899 = query.getOrDefault("Version")
  valid_602899 = validateParameter(valid_602899, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_602899 != nil:
    section.add "Version", valid_602899
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
  var valid_602900 = header.getOrDefault("X-Amz-Date")
  valid_602900 = validateParameter(valid_602900, JString, required = false,
                                 default = nil)
  if valid_602900 != nil:
    section.add "X-Amz-Date", valid_602900
  var valid_602901 = header.getOrDefault("X-Amz-Security-Token")
  valid_602901 = validateParameter(valid_602901, JString, required = false,
                                 default = nil)
  if valid_602901 != nil:
    section.add "X-Amz-Security-Token", valid_602901
  var valid_602902 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602902 = validateParameter(valid_602902, JString, required = false,
                                 default = nil)
  if valid_602902 != nil:
    section.add "X-Amz-Content-Sha256", valid_602902
  var valid_602903 = header.getOrDefault("X-Amz-Algorithm")
  valid_602903 = validateParameter(valid_602903, JString, required = false,
                                 default = nil)
  if valid_602903 != nil:
    section.add "X-Amz-Algorithm", valid_602903
  var valid_602904 = header.getOrDefault("X-Amz-Signature")
  valid_602904 = validateParameter(valid_602904, JString, required = false,
                                 default = nil)
  if valid_602904 != nil:
    section.add "X-Amz-Signature", valid_602904
  var valid_602905 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602905 = validateParameter(valid_602905, JString, required = false,
                                 default = nil)
  if valid_602905 != nil:
    section.add "X-Amz-SignedHeaders", valid_602905
  var valid_602906 = header.getOrDefault("X-Amz-Credential")
  valid_602906 = validateParameter(valid_602906, JString, required = false,
                                 default = nil)
  if valid_602906 != nil:
    section.add "X-Amz-Credential", valid_602906
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602929: Call_GetCreateDomain_602770; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new search domain.
  ## 
  let valid = call_602929.validator(path, query, header, formData, body)
  let scheme = call_602929.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602929.url(scheme.get, call_602929.host, call_602929.base,
                         call_602929.route, valid.getOrDefault("path"))
  result = hook(call_602929, url, valid)

proc call*(call_603000: Call_GetCreateDomain_602770; DomainName: string;
          Action: string = "CreateDomain"; Version: string = "2011-02-01"): Recallable =
  ## getCreateDomain
  ## Creates a new search domain.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_603001 = newJObject()
  add(query_603001, "Action", newJString(Action))
  add(query_603001, "DomainName", newJString(DomainName))
  add(query_603001, "Version", newJString(Version))
  result = call_603000.call(nil, query_603001, nil, nil, nil)

var getCreateDomain* = Call_GetCreateDomain_602770(name: "getCreateDomain",
    meth: HttpMethod.HttpGet, host: "cloudsearch.amazonaws.com",
    route: "/#Action=CreateDomain", validator: validate_GetCreateDomain_602771,
    base: "/", url: url_GetCreateDomain_602772, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDefineIndexField_603080 = ref object of OpenApiRestCall_602433
proc url_PostDefineIndexField_603082(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDefineIndexField_603081(path: JsonNode; query: JsonNode;
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
  var valid_603083 = query.getOrDefault("Action")
  valid_603083 = validateParameter(valid_603083, JString, required = true,
                                 default = newJString("DefineIndexField"))
  if valid_603083 != nil:
    section.add "Action", valid_603083
  var valid_603084 = query.getOrDefault("Version")
  valid_603084 = validateParameter(valid_603084, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_603084 != nil:
    section.add "Version", valid_603084
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
  var valid_603085 = header.getOrDefault("X-Amz-Date")
  valid_603085 = validateParameter(valid_603085, JString, required = false,
                                 default = nil)
  if valid_603085 != nil:
    section.add "X-Amz-Date", valid_603085
  var valid_603086 = header.getOrDefault("X-Amz-Security-Token")
  valid_603086 = validateParameter(valid_603086, JString, required = false,
                                 default = nil)
  if valid_603086 != nil:
    section.add "X-Amz-Security-Token", valid_603086
  var valid_603087 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603087 = validateParameter(valid_603087, JString, required = false,
                                 default = nil)
  if valid_603087 != nil:
    section.add "X-Amz-Content-Sha256", valid_603087
  var valid_603088 = header.getOrDefault("X-Amz-Algorithm")
  valid_603088 = validateParameter(valid_603088, JString, required = false,
                                 default = nil)
  if valid_603088 != nil:
    section.add "X-Amz-Algorithm", valid_603088
  var valid_603089 = header.getOrDefault("X-Amz-Signature")
  valid_603089 = validateParameter(valid_603089, JString, required = false,
                                 default = nil)
  if valid_603089 != nil:
    section.add "X-Amz-Signature", valid_603089
  var valid_603090 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603090 = validateParameter(valid_603090, JString, required = false,
                                 default = nil)
  if valid_603090 != nil:
    section.add "X-Amz-SignedHeaders", valid_603090
  var valid_603091 = header.getOrDefault("X-Amz-Credential")
  valid_603091 = validateParameter(valid_603091, JString, required = false,
                                 default = nil)
  if valid_603091 != nil:
    section.add "X-Amz-Credential", valid_603091
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
  var valid_603092 = formData.getOrDefault("IndexField.UIntOptions")
  valid_603092 = validateParameter(valid_603092, JString, required = false,
                                 default = nil)
  if valid_603092 != nil:
    section.add "IndexField.UIntOptions", valid_603092
  var valid_603093 = formData.getOrDefault("IndexField.TextOptions")
  valid_603093 = validateParameter(valid_603093, JString, required = false,
                                 default = nil)
  if valid_603093 != nil:
    section.add "IndexField.TextOptions", valid_603093
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_603094 = formData.getOrDefault("DomainName")
  valid_603094 = validateParameter(valid_603094, JString, required = true,
                                 default = nil)
  if valid_603094 != nil:
    section.add "DomainName", valid_603094
  var valid_603095 = formData.getOrDefault("IndexField.LiteralOptions")
  valid_603095 = validateParameter(valid_603095, JString, required = false,
                                 default = nil)
  if valid_603095 != nil:
    section.add "IndexField.LiteralOptions", valid_603095
  var valid_603096 = formData.getOrDefault("IndexField.IndexFieldType")
  valid_603096 = validateParameter(valid_603096, JString, required = false,
                                 default = nil)
  if valid_603096 != nil:
    section.add "IndexField.IndexFieldType", valid_603096
  var valid_603097 = formData.getOrDefault("IndexField.IndexFieldName")
  valid_603097 = validateParameter(valid_603097, JString, required = false,
                                 default = nil)
  if valid_603097 != nil:
    section.add "IndexField.IndexFieldName", valid_603097
  var valid_603098 = formData.getOrDefault("IndexField.SourceAttributes")
  valid_603098 = validateParameter(valid_603098, JArray, required = false,
                                 default = nil)
  if valid_603098 != nil:
    section.add "IndexField.SourceAttributes", valid_603098
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603099: Call_PostDefineIndexField_603080; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures an <code>IndexField</code> for the search domain. Used to create new fields and modify existing ones. If the field exists, the new configuration replaces the old one. You can configure a maximum of 200 index fields.
  ## 
  let valid = call_603099.validator(path, query, header, formData, body)
  let scheme = call_603099.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603099.url(scheme.get, call_603099.host, call_603099.base,
                         call_603099.route, valid.getOrDefault("path"))
  result = hook(call_603099, url, valid)

proc call*(call_603100: Call_PostDefineIndexField_603080; DomainName: string;
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
  var query_603101 = newJObject()
  var formData_603102 = newJObject()
  add(formData_603102, "IndexField.UIntOptions", newJString(IndexFieldUIntOptions))
  add(formData_603102, "IndexField.TextOptions", newJString(IndexFieldTextOptions))
  add(formData_603102, "DomainName", newJString(DomainName))
  add(formData_603102, "IndexField.LiteralOptions",
      newJString(IndexFieldLiteralOptions))
  add(formData_603102, "IndexField.IndexFieldType",
      newJString(IndexFieldIndexFieldType))
  add(query_603101, "Action", newJString(Action))
  add(formData_603102, "IndexField.IndexFieldName",
      newJString(IndexFieldIndexFieldName))
  add(query_603101, "Version", newJString(Version))
  if IndexFieldSourceAttributes != nil:
    formData_603102.add "IndexField.SourceAttributes", IndexFieldSourceAttributes
  result = call_603100.call(nil, query_603101, nil, formData_603102, nil)

var postDefineIndexField* = Call_PostDefineIndexField_603080(
    name: "postDefineIndexField", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineIndexField",
    validator: validate_PostDefineIndexField_603081, base: "/",
    url: url_PostDefineIndexField_603082, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDefineIndexField_603058 = ref object of OpenApiRestCall_602433
proc url_GetDefineIndexField_603060(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDefineIndexField_603059(path: JsonNode; query: JsonNode;
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
  var valid_603061 = query.getOrDefault("IndexField.TextOptions")
  valid_603061 = validateParameter(valid_603061, JString, required = false,
                                 default = nil)
  if valid_603061 != nil:
    section.add "IndexField.TextOptions", valid_603061
  var valid_603062 = query.getOrDefault("IndexField.LiteralOptions")
  valid_603062 = validateParameter(valid_603062, JString, required = false,
                                 default = nil)
  if valid_603062 != nil:
    section.add "IndexField.LiteralOptions", valid_603062
  var valid_603063 = query.getOrDefault("IndexField.UIntOptions")
  valid_603063 = validateParameter(valid_603063, JString, required = false,
                                 default = nil)
  if valid_603063 != nil:
    section.add "IndexField.UIntOptions", valid_603063
  var valid_603064 = query.getOrDefault("IndexField.IndexFieldType")
  valid_603064 = validateParameter(valid_603064, JString, required = false,
                                 default = nil)
  if valid_603064 != nil:
    section.add "IndexField.IndexFieldType", valid_603064
  var valid_603065 = query.getOrDefault("IndexField.SourceAttributes")
  valid_603065 = validateParameter(valid_603065, JArray, required = false,
                                 default = nil)
  if valid_603065 != nil:
    section.add "IndexField.SourceAttributes", valid_603065
  var valid_603066 = query.getOrDefault("IndexField.IndexFieldName")
  valid_603066 = validateParameter(valid_603066, JString, required = false,
                                 default = nil)
  if valid_603066 != nil:
    section.add "IndexField.IndexFieldName", valid_603066
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603067 = query.getOrDefault("Action")
  valid_603067 = validateParameter(valid_603067, JString, required = true,
                                 default = newJString("DefineIndexField"))
  if valid_603067 != nil:
    section.add "Action", valid_603067
  var valid_603068 = query.getOrDefault("DomainName")
  valid_603068 = validateParameter(valid_603068, JString, required = true,
                                 default = nil)
  if valid_603068 != nil:
    section.add "DomainName", valid_603068
  var valid_603069 = query.getOrDefault("Version")
  valid_603069 = validateParameter(valid_603069, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_603069 != nil:
    section.add "Version", valid_603069
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
  var valid_603070 = header.getOrDefault("X-Amz-Date")
  valid_603070 = validateParameter(valid_603070, JString, required = false,
                                 default = nil)
  if valid_603070 != nil:
    section.add "X-Amz-Date", valid_603070
  var valid_603071 = header.getOrDefault("X-Amz-Security-Token")
  valid_603071 = validateParameter(valid_603071, JString, required = false,
                                 default = nil)
  if valid_603071 != nil:
    section.add "X-Amz-Security-Token", valid_603071
  var valid_603072 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603072 = validateParameter(valid_603072, JString, required = false,
                                 default = nil)
  if valid_603072 != nil:
    section.add "X-Amz-Content-Sha256", valid_603072
  var valid_603073 = header.getOrDefault("X-Amz-Algorithm")
  valid_603073 = validateParameter(valid_603073, JString, required = false,
                                 default = nil)
  if valid_603073 != nil:
    section.add "X-Amz-Algorithm", valid_603073
  var valid_603074 = header.getOrDefault("X-Amz-Signature")
  valid_603074 = validateParameter(valid_603074, JString, required = false,
                                 default = nil)
  if valid_603074 != nil:
    section.add "X-Amz-Signature", valid_603074
  var valid_603075 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603075 = validateParameter(valid_603075, JString, required = false,
                                 default = nil)
  if valid_603075 != nil:
    section.add "X-Amz-SignedHeaders", valid_603075
  var valid_603076 = header.getOrDefault("X-Amz-Credential")
  valid_603076 = validateParameter(valid_603076, JString, required = false,
                                 default = nil)
  if valid_603076 != nil:
    section.add "X-Amz-Credential", valid_603076
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603077: Call_GetDefineIndexField_603058; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures an <code>IndexField</code> for the search domain. Used to create new fields and modify existing ones. If the field exists, the new configuration replaces the old one. You can configure a maximum of 200 index fields.
  ## 
  let valid = call_603077.validator(path, query, header, formData, body)
  let scheme = call_603077.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603077.url(scheme.get, call_603077.host, call_603077.base,
                         call_603077.route, valid.getOrDefault("path"))
  result = hook(call_603077, url, valid)

proc call*(call_603078: Call_GetDefineIndexField_603058; DomainName: string;
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
  var query_603079 = newJObject()
  add(query_603079, "IndexField.TextOptions", newJString(IndexFieldTextOptions))
  add(query_603079, "IndexField.LiteralOptions",
      newJString(IndexFieldLiteralOptions))
  add(query_603079, "IndexField.UIntOptions", newJString(IndexFieldUIntOptions))
  add(query_603079, "IndexField.IndexFieldType",
      newJString(IndexFieldIndexFieldType))
  if IndexFieldSourceAttributes != nil:
    query_603079.add "IndexField.SourceAttributes", IndexFieldSourceAttributes
  add(query_603079, "IndexField.IndexFieldName",
      newJString(IndexFieldIndexFieldName))
  add(query_603079, "Action", newJString(Action))
  add(query_603079, "DomainName", newJString(DomainName))
  add(query_603079, "Version", newJString(Version))
  result = call_603078.call(nil, query_603079, nil, nil, nil)

var getDefineIndexField* = Call_GetDefineIndexField_603058(
    name: "getDefineIndexField", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineIndexField",
    validator: validate_GetDefineIndexField_603059, base: "/",
    url: url_GetDefineIndexField_603060, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDefineRankExpression_603121 = ref object of OpenApiRestCall_602433
proc url_PostDefineRankExpression_603123(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDefineRankExpression_603122(path: JsonNode; query: JsonNode;
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
  var valid_603124 = query.getOrDefault("Action")
  valid_603124 = validateParameter(valid_603124, JString, required = true,
                                 default = newJString("DefineRankExpression"))
  if valid_603124 != nil:
    section.add "Action", valid_603124
  var valid_603125 = query.getOrDefault("Version")
  valid_603125 = validateParameter(valid_603125, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_603125 != nil:
    section.add "Version", valid_603125
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
  var valid_603126 = header.getOrDefault("X-Amz-Date")
  valid_603126 = validateParameter(valid_603126, JString, required = false,
                                 default = nil)
  if valid_603126 != nil:
    section.add "X-Amz-Date", valid_603126
  var valid_603127 = header.getOrDefault("X-Amz-Security-Token")
  valid_603127 = validateParameter(valid_603127, JString, required = false,
                                 default = nil)
  if valid_603127 != nil:
    section.add "X-Amz-Security-Token", valid_603127
  var valid_603128 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603128 = validateParameter(valid_603128, JString, required = false,
                                 default = nil)
  if valid_603128 != nil:
    section.add "X-Amz-Content-Sha256", valid_603128
  var valid_603129 = header.getOrDefault("X-Amz-Algorithm")
  valid_603129 = validateParameter(valid_603129, JString, required = false,
                                 default = nil)
  if valid_603129 != nil:
    section.add "X-Amz-Algorithm", valid_603129
  var valid_603130 = header.getOrDefault("X-Amz-Signature")
  valid_603130 = validateParameter(valid_603130, JString, required = false,
                                 default = nil)
  if valid_603130 != nil:
    section.add "X-Amz-Signature", valid_603130
  var valid_603131 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603131 = validateParameter(valid_603131, JString, required = false,
                                 default = nil)
  if valid_603131 != nil:
    section.add "X-Amz-SignedHeaders", valid_603131
  var valid_603132 = header.getOrDefault("X-Amz-Credential")
  valid_603132 = validateParameter(valid_603132, JString, required = false,
                                 default = nil)
  if valid_603132 != nil:
    section.add "X-Amz-Credential", valid_603132
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
  var valid_603133 = formData.getOrDefault("DomainName")
  valid_603133 = validateParameter(valid_603133, JString, required = true,
                                 default = nil)
  if valid_603133 != nil:
    section.add "DomainName", valid_603133
  var valid_603134 = formData.getOrDefault("RankExpression.RankName")
  valid_603134 = validateParameter(valid_603134, JString, required = false,
                                 default = nil)
  if valid_603134 != nil:
    section.add "RankExpression.RankName", valid_603134
  var valid_603135 = formData.getOrDefault("RankExpression.RankExpression")
  valid_603135 = validateParameter(valid_603135, JString, required = false,
                                 default = nil)
  if valid_603135 != nil:
    section.add "RankExpression.RankExpression", valid_603135
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603136: Call_PostDefineRankExpression_603121; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a <code>RankExpression</code> for the search domain. Used to create new rank expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. You can configure a maximum of 50 rank expressions.
  ## 
  let valid = call_603136.validator(path, query, header, formData, body)
  let scheme = call_603136.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603136.url(scheme.get, call_603136.host, call_603136.base,
                         call_603136.route, valid.getOrDefault("path"))
  result = hook(call_603136, url, valid)

proc call*(call_603137: Call_PostDefineRankExpression_603121; DomainName: string;
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
  var query_603138 = newJObject()
  var formData_603139 = newJObject()
  add(formData_603139, "DomainName", newJString(DomainName))
  add(formData_603139, "RankExpression.RankName",
      newJString(RankExpressionRankName))
  add(formData_603139, "RankExpression.RankExpression",
      newJString(RankExpressionRankExpression))
  add(query_603138, "Action", newJString(Action))
  add(query_603138, "Version", newJString(Version))
  result = call_603137.call(nil, query_603138, nil, formData_603139, nil)

var postDefineRankExpression* = Call_PostDefineRankExpression_603121(
    name: "postDefineRankExpression", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineRankExpression",
    validator: validate_PostDefineRankExpression_603122, base: "/",
    url: url_PostDefineRankExpression_603123, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDefineRankExpression_603103 = ref object of OpenApiRestCall_602433
proc url_GetDefineRankExpression_603105(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDefineRankExpression_603104(path: JsonNode; query: JsonNode;
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
  var valid_603106 = query.getOrDefault("Action")
  valid_603106 = validateParameter(valid_603106, JString, required = true,
                                 default = newJString("DefineRankExpression"))
  if valid_603106 != nil:
    section.add "Action", valid_603106
  var valid_603107 = query.getOrDefault("RankExpression.RankExpression")
  valid_603107 = validateParameter(valid_603107, JString, required = false,
                                 default = nil)
  if valid_603107 != nil:
    section.add "RankExpression.RankExpression", valid_603107
  var valid_603108 = query.getOrDefault("RankExpression.RankName")
  valid_603108 = validateParameter(valid_603108, JString, required = false,
                                 default = nil)
  if valid_603108 != nil:
    section.add "RankExpression.RankName", valid_603108
  var valid_603109 = query.getOrDefault("DomainName")
  valid_603109 = validateParameter(valid_603109, JString, required = true,
                                 default = nil)
  if valid_603109 != nil:
    section.add "DomainName", valid_603109
  var valid_603110 = query.getOrDefault("Version")
  valid_603110 = validateParameter(valid_603110, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_603110 != nil:
    section.add "Version", valid_603110
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
  var valid_603111 = header.getOrDefault("X-Amz-Date")
  valid_603111 = validateParameter(valid_603111, JString, required = false,
                                 default = nil)
  if valid_603111 != nil:
    section.add "X-Amz-Date", valid_603111
  var valid_603112 = header.getOrDefault("X-Amz-Security-Token")
  valid_603112 = validateParameter(valid_603112, JString, required = false,
                                 default = nil)
  if valid_603112 != nil:
    section.add "X-Amz-Security-Token", valid_603112
  var valid_603113 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603113 = validateParameter(valid_603113, JString, required = false,
                                 default = nil)
  if valid_603113 != nil:
    section.add "X-Amz-Content-Sha256", valid_603113
  var valid_603114 = header.getOrDefault("X-Amz-Algorithm")
  valid_603114 = validateParameter(valid_603114, JString, required = false,
                                 default = nil)
  if valid_603114 != nil:
    section.add "X-Amz-Algorithm", valid_603114
  var valid_603115 = header.getOrDefault("X-Amz-Signature")
  valid_603115 = validateParameter(valid_603115, JString, required = false,
                                 default = nil)
  if valid_603115 != nil:
    section.add "X-Amz-Signature", valid_603115
  var valid_603116 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603116 = validateParameter(valid_603116, JString, required = false,
                                 default = nil)
  if valid_603116 != nil:
    section.add "X-Amz-SignedHeaders", valid_603116
  var valid_603117 = header.getOrDefault("X-Amz-Credential")
  valid_603117 = validateParameter(valid_603117, JString, required = false,
                                 default = nil)
  if valid_603117 != nil:
    section.add "X-Amz-Credential", valid_603117
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603118: Call_GetDefineRankExpression_603103; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a <code>RankExpression</code> for the search domain. Used to create new rank expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. You can configure a maximum of 50 rank expressions.
  ## 
  let valid = call_603118.validator(path, query, header, formData, body)
  let scheme = call_603118.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603118.url(scheme.get, call_603118.host, call_603118.base,
                         call_603118.route, valid.getOrDefault("path"))
  result = hook(call_603118, url, valid)

proc call*(call_603119: Call_GetDefineRankExpression_603103; DomainName: string;
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
  var query_603120 = newJObject()
  add(query_603120, "Action", newJString(Action))
  add(query_603120, "RankExpression.RankExpression",
      newJString(RankExpressionRankExpression))
  add(query_603120, "RankExpression.RankName", newJString(RankExpressionRankName))
  add(query_603120, "DomainName", newJString(DomainName))
  add(query_603120, "Version", newJString(Version))
  result = call_603119.call(nil, query_603120, nil, nil, nil)

var getDefineRankExpression* = Call_GetDefineRankExpression_603103(
    name: "getDefineRankExpression", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineRankExpression",
    validator: validate_GetDefineRankExpression_603104, base: "/",
    url: url_GetDefineRankExpression_603105, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDomain_603156 = ref object of OpenApiRestCall_602433
proc url_PostDeleteDomain_603158(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteDomain_603157(path: JsonNode; query: JsonNode;
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
  var valid_603159 = query.getOrDefault("Action")
  valid_603159 = validateParameter(valid_603159, JString, required = true,
                                 default = newJString("DeleteDomain"))
  if valid_603159 != nil:
    section.add "Action", valid_603159
  var valid_603160 = query.getOrDefault("Version")
  valid_603160 = validateParameter(valid_603160, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_603160 != nil:
    section.add "Version", valid_603160
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
  var valid_603161 = header.getOrDefault("X-Amz-Date")
  valid_603161 = validateParameter(valid_603161, JString, required = false,
                                 default = nil)
  if valid_603161 != nil:
    section.add "X-Amz-Date", valid_603161
  var valid_603162 = header.getOrDefault("X-Amz-Security-Token")
  valid_603162 = validateParameter(valid_603162, JString, required = false,
                                 default = nil)
  if valid_603162 != nil:
    section.add "X-Amz-Security-Token", valid_603162
  var valid_603163 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603163 = validateParameter(valid_603163, JString, required = false,
                                 default = nil)
  if valid_603163 != nil:
    section.add "X-Amz-Content-Sha256", valid_603163
  var valid_603164 = header.getOrDefault("X-Amz-Algorithm")
  valid_603164 = validateParameter(valid_603164, JString, required = false,
                                 default = nil)
  if valid_603164 != nil:
    section.add "X-Amz-Algorithm", valid_603164
  var valid_603165 = header.getOrDefault("X-Amz-Signature")
  valid_603165 = validateParameter(valid_603165, JString, required = false,
                                 default = nil)
  if valid_603165 != nil:
    section.add "X-Amz-Signature", valid_603165
  var valid_603166 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603166 = validateParameter(valid_603166, JString, required = false,
                                 default = nil)
  if valid_603166 != nil:
    section.add "X-Amz-SignedHeaders", valid_603166
  var valid_603167 = header.getOrDefault("X-Amz-Credential")
  valid_603167 = validateParameter(valid_603167, JString, required = false,
                                 default = nil)
  if valid_603167 != nil:
    section.add "X-Amz-Credential", valid_603167
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_603168 = formData.getOrDefault("DomainName")
  valid_603168 = validateParameter(valid_603168, JString, required = true,
                                 default = nil)
  if valid_603168 != nil:
    section.add "DomainName", valid_603168
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603169: Call_PostDeleteDomain_603156; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently deletes a search domain and all of its data.
  ## 
  let valid = call_603169.validator(path, query, header, formData, body)
  let scheme = call_603169.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603169.url(scheme.get, call_603169.host, call_603169.base,
                         call_603169.route, valid.getOrDefault("path"))
  result = hook(call_603169, url, valid)

proc call*(call_603170: Call_PostDeleteDomain_603156; DomainName: string;
          Action: string = "DeleteDomain"; Version: string = "2011-02-01"): Recallable =
  ## postDeleteDomain
  ## Permanently deletes a search domain and all of its data.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603171 = newJObject()
  var formData_603172 = newJObject()
  add(formData_603172, "DomainName", newJString(DomainName))
  add(query_603171, "Action", newJString(Action))
  add(query_603171, "Version", newJString(Version))
  result = call_603170.call(nil, query_603171, nil, formData_603172, nil)

var postDeleteDomain* = Call_PostDeleteDomain_603156(name: "postDeleteDomain",
    meth: HttpMethod.HttpPost, host: "cloudsearch.amazonaws.com",
    route: "/#Action=DeleteDomain", validator: validate_PostDeleteDomain_603157,
    base: "/", url: url_PostDeleteDomain_603158,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDomain_603140 = ref object of OpenApiRestCall_602433
proc url_GetDeleteDomain_603142(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteDomain_603141(path: JsonNode; query: JsonNode;
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
  var valid_603143 = query.getOrDefault("Action")
  valid_603143 = validateParameter(valid_603143, JString, required = true,
                                 default = newJString("DeleteDomain"))
  if valid_603143 != nil:
    section.add "Action", valid_603143
  var valid_603144 = query.getOrDefault("DomainName")
  valid_603144 = validateParameter(valid_603144, JString, required = true,
                                 default = nil)
  if valid_603144 != nil:
    section.add "DomainName", valid_603144
  var valid_603145 = query.getOrDefault("Version")
  valid_603145 = validateParameter(valid_603145, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_603145 != nil:
    section.add "Version", valid_603145
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
  var valid_603146 = header.getOrDefault("X-Amz-Date")
  valid_603146 = validateParameter(valid_603146, JString, required = false,
                                 default = nil)
  if valid_603146 != nil:
    section.add "X-Amz-Date", valid_603146
  var valid_603147 = header.getOrDefault("X-Amz-Security-Token")
  valid_603147 = validateParameter(valid_603147, JString, required = false,
                                 default = nil)
  if valid_603147 != nil:
    section.add "X-Amz-Security-Token", valid_603147
  var valid_603148 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603148 = validateParameter(valid_603148, JString, required = false,
                                 default = nil)
  if valid_603148 != nil:
    section.add "X-Amz-Content-Sha256", valid_603148
  var valid_603149 = header.getOrDefault("X-Amz-Algorithm")
  valid_603149 = validateParameter(valid_603149, JString, required = false,
                                 default = nil)
  if valid_603149 != nil:
    section.add "X-Amz-Algorithm", valid_603149
  var valid_603150 = header.getOrDefault("X-Amz-Signature")
  valid_603150 = validateParameter(valid_603150, JString, required = false,
                                 default = nil)
  if valid_603150 != nil:
    section.add "X-Amz-Signature", valid_603150
  var valid_603151 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603151 = validateParameter(valid_603151, JString, required = false,
                                 default = nil)
  if valid_603151 != nil:
    section.add "X-Amz-SignedHeaders", valid_603151
  var valid_603152 = header.getOrDefault("X-Amz-Credential")
  valid_603152 = validateParameter(valid_603152, JString, required = false,
                                 default = nil)
  if valid_603152 != nil:
    section.add "X-Amz-Credential", valid_603152
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603153: Call_GetDeleteDomain_603140; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently deletes a search domain and all of its data.
  ## 
  let valid = call_603153.validator(path, query, header, formData, body)
  let scheme = call_603153.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603153.url(scheme.get, call_603153.host, call_603153.base,
                         call_603153.route, valid.getOrDefault("path"))
  result = hook(call_603153, url, valid)

proc call*(call_603154: Call_GetDeleteDomain_603140; DomainName: string;
          Action: string = "DeleteDomain"; Version: string = "2011-02-01"): Recallable =
  ## getDeleteDomain
  ## Permanently deletes a search domain and all of its data.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_603155 = newJObject()
  add(query_603155, "Action", newJString(Action))
  add(query_603155, "DomainName", newJString(DomainName))
  add(query_603155, "Version", newJString(Version))
  result = call_603154.call(nil, query_603155, nil, nil, nil)

var getDeleteDomain* = Call_GetDeleteDomain_603140(name: "getDeleteDomain",
    meth: HttpMethod.HttpGet, host: "cloudsearch.amazonaws.com",
    route: "/#Action=DeleteDomain", validator: validate_GetDeleteDomain_603141,
    base: "/", url: url_GetDeleteDomain_603142, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteIndexField_603190 = ref object of OpenApiRestCall_602433
proc url_PostDeleteIndexField_603192(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteIndexField_603191(path: JsonNode; query: JsonNode;
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
  var valid_603193 = query.getOrDefault("Action")
  valid_603193 = validateParameter(valid_603193, JString, required = true,
                                 default = newJString("DeleteIndexField"))
  if valid_603193 != nil:
    section.add "Action", valid_603193
  var valid_603194 = query.getOrDefault("Version")
  valid_603194 = validateParameter(valid_603194, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_603194 != nil:
    section.add "Version", valid_603194
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
  var valid_603195 = header.getOrDefault("X-Amz-Date")
  valid_603195 = validateParameter(valid_603195, JString, required = false,
                                 default = nil)
  if valid_603195 != nil:
    section.add "X-Amz-Date", valid_603195
  var valid_603196 = header.getOrDefault("X-Amz-Security-Token")
  valid_603196 = validateParameter(valid_603196, JString, required = false,
                                 default = nil)
  if valid_603196 != nil:
    section.add "X-Amz-Security-Token", valid_603196
  var valid_603197 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603197 = validateParameter(valid_603197, JString, required = false,
                                 default = nil)
  if valid_603197 != nil:
    section.add "X-Amz-Content-Sha256", valid_603197
  var valid_603198 = header.getOrDefault("X-Amz-Algorithm")
  valid_603198 = validateParameter(valid_603198, JString, required = false,
                                 default = nil)
  if valid_603198 != nil:
    section.add "X-Amz-Algorithm", valid_603198
  var valid_603199 = header.getOrDefault("X-Amz-Signature")
  valid_603199 = validateParameter(valid_603199, JString, required = false,
                                 default = nil)
  if valid_603199 != nil:
    section.add "X-Amz-Signature", valid_603199
  var valid_603200 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603200 = validateParameter(valid_603200, JString, required = false,
                                 default = nil)
  if valid_603200 != nil:
    section.add "X-Amz-SignedHeaders", valid_603200
  var valid_603201 = header.getOrDefault("X-Amz-Credential")
  valid_603201 = validateParameter(valid_603201, JString, required = false,
                                 default = nil)
  if valid_603201 != nil:
    section.add "X-Amz-Credential", valid_603201
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   IndexFieldName: JString (required)
  ##                 : A string that represents the name of an index field. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_603202 = formData.getOrDefault("DomainName")
  valid_603202 = validateParameter(valid_603202, JString, required = true,
                                 default = nil)
  if valid_603202 != nil:
    section.add "DomainName", valid_603202
  var valid_603203 = formData.getOrDefault("IndexFieldName")
  valid_603203 = validateParameter(valid_603203, JString, required = true,
                                 default = nil)
  if valid_603203 != nil:
    section.add "IndexFieldName", valid_603203
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603204: Call_PostDeleteIndexField_603190; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes an <code>IndexField</code> from the search domain.
  ## 
  let valid = call_603204.validator(path, query, header, formData, body)
  let scheme = call_603204.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603204.url(scheme.get, call_603204.host, call_603204.base,
                         call_603204.route, valid.getOrDefault("path"))
  result = hook(call_603204, url, valid)

proc call*(call_603205: Call_PostDeleteIndexField_603190; DomainName: string;
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
  var query_603206 = newJObject()
  var formData_603207 = newJObject()
  add(formData_603207, "DomainName", newJString(DomainName))
  add(formData_603207, "IndexFieldName", newJString(IndexFieldName))
  add(query_603206, "Action", newJString(Action))
  add(query_603206, "Version", newJString(Version))
  result = call_603205.call(nil, query_603206, nil, formData_603207, nil)

var postDeleteIndexField* = Call_PostDeleteIndexField_603190(
    name: "postDeleteIndexField", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteIndexField",
    validator: validate_PostDeleteIndexField_603191, base: "/",
    url: url_PostDeleteIndexField_603192, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteIndexField_603173 = ref object of OpenApiRestCall_602433
proc url_GetDeleteIndexField_603175(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteIndexField_603174(path: JsonNode; query: JsonNode;
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
  var valid_603176 = query.getOrDefault("IndexFieldName")
  valid_603176 = validateParameter(valid_603176, JString, required = true,
                                 default = nil)
  if valid_603176 != nil:
    section.add "IndexFieldName", valid_603176
  var valid_603177 = query.getOrDefault("Action")
  valid_603177 = validateParameter(valid_603177, JString, required = true,
                                 default = newJString("DeleteIndexField"))
  if valid_603177 != nil:
    section.add "Action", valid_603177
  var valid_603178 = query.getOrDefault("DomainName")
  valid_603178 = validateParameter(valid_603178, JString, required = true,
                                 default = nil)
  if valid_603178 != nil:
    section.add "DomainName", valid_603178
  var valid_603179 = query.getOrDefault("Version")
  valid_603179 = validateParameter(valid_603179, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_603179 != nil:
    section.add "Version", valid_603179
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
  var valid_603180 = header.getOrDefault("X-Amz-Date")
  valid_603180 = validateParameter(valid_603180, JString, required = false,
                                 default = nil)
  if valid_603180 != nil:
    section.add "X-Amz-Date", valid_603180
  var valid_603181 = header.getOrDefault("X-Amz-Security-Token")
  valid_603181 = validateParameter(valid_603181, JString, required = false,
                                 default = nil)
  if valid_603181 != nil:
    section.add "X-Amz-Security-Token", valid_603181
  var valid_603182 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603182 = validateParameter(valid_603182, JString, required = false,
                                 default = nil)
  if valid_603182 != nil:
    section.add "X-Amz-Content-Sha256", valid_603182
  var valid_603183 = header.getOrDefault("X-Amz-Algorithm")
  valid_603183 = validateParameter(valid_603183, JString, required = false,
                                 default = nil)
  if valid_603183 != nil:
    section.add "X-Amz-Algorithm", valid_603183
  var valid_603184 = header.getOrDefault("X-Amz-Signature")
  valid_603184 = validateParameter(valid_603184, JString, required = false,
                                 default = nil)
  if valid_603184 != nil:
    section.add "X-Amz-Signature", valid_603184
  var valid_603185 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603185 = validateParameter(valid_603185, JString, required = false,
                                 default = nil)
  if valid_603185 != nil:
    section.add "X-Amz-SignedHeaders", valid_603185
  var valid_603186 = header.getOrDefault("X-Amz-Credential")
  valid_603186 = validateParameter(valid_603186, JString, required = false,
                                 default = nil)
  if valid_603186 != nil:
    section.add "X-Amz-Credential", valid_603186
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603187: Call_GetDeleteIndexField_603173; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes an <code>IndexField</code> from the search domain.
  ## 
  let valid = call_603187.validator(path, query, header, formData, body)
  let scheme = call_603187.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603187.url(scheme.get, call_603187.host, call_603187.base,
                         call_603187.route, valid.getOrDefault("path"))
  result = hook(call_603187, url, valid)

proc call*(call_603188: Call_GetDeleteIndexField_603173; IndexFieldName: string;
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
  var query_603189 = newJObject()
  add(query_603189, "IndexFieldName", newJString(IndexFieldName))
  add(query_603189, "Action", newJString(Action))
  add(query_603189, "DomainName", newJString(DomainName))
  add(query_603189, "Version", newJString(Version))
  result = call_603188.call(nil, query_603189, nil, nil, nil)

var getDeleteIndexField* = Call_GetDeleteIndexField_603173(
    name: "getDeleteIndexField", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteIndexField",
    validator: validate_GetDeleteIndexField_603174, base: "/",
    url: url_GetDeleteIndexField_603175, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteRankExpression_603225 = ref object of OpenApiRestCall_602433
proc url_PostDeleteRankExpression_603227(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteRankExpression_603226(path: JsonNode; query: JsonNode;
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
  var valid_603228 = query.getOrDefault("Action")
  valid_603228 = validateParameter(valid_603228, JString, required = true,
                                 default = newJString("DeleteRankExpression"))
  if valid_603228 != nil:
    section.add "Action", valid_603228
  var valid_603229 = query.getOrDefault("Version")
  valid_603229 = validateParameter(valid_603229, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_603229 != nil:
    section.add "Version", valid_603229
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
  var valid_603230 = header.getOrDefault("X-Amz-Date")
  valid_603230 = validateParameter(valid_603230, JString, required = false,
                                 default = nil)
  if valid_603230 != nil:
    section.add "X-Amz-Date", valid_603230
  var valid_603231 = header.getOrDefault("X-Amz-Security-Token")
  valid_603231 = validateParameter(valid_603231, JString, required = false,
                                 default = nil)
  if valid_603231 != nil:
    section.add "X-Amz-Security-Token", valid_603231
  var valid_603232 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603232 = validateParameter(valid_603232, JString, required = false,
                                 default = nil)
  if valid_603232 != nil:
    section.add "X-Amz-Content-Sha256", valid_603232
  var valid_603233 = header.getOrDefault("X-Amz-Algorithm")
  valid_603233 = validateParameter(valid_603233, JString, required = false,
                                 default = nil)
  if valid_603233 != nil:
    section.add "X-Amz-Algorithm", valid_603233
  var valid_603234 = header.getOrDefault("X-Amz-Signature")
  valid_603234 = validateParameter(valid_603234, JString, required = false,
                                 default = nil)
  if valid_603234 != nil:
    section.add "X-Amz-Signature", valid_603234
  var valid_603235 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603235 = validateParameter(valid_603235, JString, required = false,
                                 default = nil)
  if valid_603235 != nil:
    section.add "X-Amz-SignedHeaders", valid_603235
  var valid_603236 = header.getOrDefault("X-Amz-Credential")
  valid_603236 = validateParameter(valid_603236, JString, required = false,
                                 default = nil)
  if valid_603236 != nil:
    section.add "X-Amz-Credential", valid_603236
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   RankName: JString (required)
  ##           : A string that represents the name of an index field. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_603237 = formData.getOrDefault("DomainName")
  valid_603237 = validateParameter(valid_603237, JString, required = true,
                                 default = nil)
  if valid_603237 != nil:
    section.add "DomainName", valid_603237
  var valid_603238 = formData.getOrDefault("RankName")
  valid_603238 = validateParameter(valid_603238, JString, required = true,
                                 default = nil)
  if valid_603238 != nil:
    section.add "RankName", valid_603238
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603239: Call_PostDeleteRankExpression_603225; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a <code>RankExpression</code> from the search domain.
  ## 
  let valid = call_603239.validator(path, query, header, formData, body)
  let scheme = call_603239.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603239.url(scheme.get, call_603239.host, call_603239.base,
                         call_603239.route, valid.getOrDefault("path"))
  result = hook(call_603239, url, valid)

proc call*(call_603240: Call_PostDeleteRankExpression_603225; DomainName: string;
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
  var query_603241 = newJObject()
  var formData_603242 = newJObject()
  add(formData_603242, "DomainName", newJString(DomainName))
  add(query_603241, "Action", newJString(Action))
  add(formData_603242, "RankName", newJString(RankName))
  add(query_603241, "Version", newJString(Version))
  result = call_603240.call(nil, query_603241, nil, formData_603242, nil)

var postDeleteRankExpression* = Call_PostDeleteRankExpression_603225(
    name: "postDeleteRankExpression", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteRankExpression",
    validator: validate_PostDeleteRankExpression_603226, base: "/",
    url: url_PostDeleteRankExpression_603227, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteRankExpression_603208 = ref object of OpenApiRestCall_602433
proc url_GetDeleteRankExpression_603210(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteRankExpression_603209(path: JsonNode; query: JsonNode;
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
  var valid_603211 = query.getOrDefault("RankName")
  valid_603211 = validateParameter(valid_603211, JString, required = true,
                                 default = nil)
  if valid_603211 != nil:
    section.add "RankName", valid_603211
  var valid_603212 = query.getOrDefault("Action")
  valid_603212 = validateParameter(valid_603212, JString, required = true,
                                 default = newJString("DeleteRankExpression"))
  if valid_603212 != nil:
    section.add "Action", valid_603212
  var valid_603213 = query.getOrDefault("DomainName")
  valid_603213 = validateParameter(valid_603213, JString, required = true,
                                 default = nil)
  if valid_603213 != nil:
    section.add "DomainName", valid_603213
  var valid_603214 = query.getOrDefault("Version")
  valid_603214 = validateParameter(valid_603214, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_603214 != nil:
    section.add "Version", valid_603214
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
  var valid_603215 = header.getOrDefault("X-Amz-Date")
  valid_603215 = validateParameter(valid_603215, JString, required = false,
                                 default = nil)
  if valid_603215 != nil:
    section.add "X-Amz-Date", valid_603215
  var valid_603216 = header.getOrDefault("X-Amz-Security-Token")
  valid_603216 = validateParameter(valid_603216, JString, required = false,
                                 default = nil)
  if valid_603216 != nil:
    section.add "X-Amz-Security-Token", valid_603216
  var valid_603217 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603217 = validateParameter(valid_603217, JString, required = false,
                                 default = nil)
  if valid_603217 != nil:
    section.add "X-Amz-Content-Sha256", valid_603217
  var valid_603218 = header.getOrDefault("X-Amz-Algorithm")
  valid_603218 = validateParameter(valid_603218, JString, required = false,
                                 default = nil)
  if valid_603218 != nil:
    section.add "X-Amz-Algorithm", valid_603218
  var valid_603219 = header.getOrDefault("X-Amz-Signature")
  valid_603219 = validateParameter(valid_603219, JString, required = false,
                                 default = nil)
  if valid_603219 != nil:
    section.add "X-Amz-Signature", valid_603219
  var valid_603220 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603220 = validateParameter(valid_603220, JString, required = false,
                                 default = nil)
  if valid_603220 != nil:
    section.add "X-Amz-SignedHeaders", valid_603220
  var valid_603221 = header.getOrDefault("X-Amz-Credential")
  valid_603221 = validateParameter(valid_603221, JString, required = false,
                                 default = nil)
  if valid_603221 != nil:
    section.add "X-Amz-Credential", valid_603221
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603222: Call_GetDeleteRankExpression_603208; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a <code>RankExpression</code> from the search domain.
  ## 
  let valid = call_603222.validator(path, query, header, formData, body)
  let scheme = call_603222.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603222.url(scheme.get, call_603222.host, call_603222.base,
                         call_603222.route, valid.getOrDefault("path"))
  result = hook(call_603222, url, valid)

proc call*(call_603223: Call_GetDeleteRankExpression_603208; RankName: string;
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
  var query_603224 = newJObject()
  add(query_603224, "RankName", newJString(RankName))
  add(query_603224, "Action", newJString(Action))
  add(query_603224, "DomainName", newJString(DomainName))
  add(query_603224, "Version", newJString(Version))
  result = call_603223.call(nil, query_603224, nil, nil, nil)

var getDeleteRankExpression* = Call_GetDeleteRankExpression_603208(
    name: "getDeleteRankExpression", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteRankExpression",
    validator: validate_GetDeleteRankExpression_603209, base: "/",
    url: url_GetDeleteRankExpression_603210, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAvailabilityOptions_603259 = ref object of OpenApiRestCall_602433
proc url_PostDescribeAvailabilityOptions_603261(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeAvailabilityOptions_603260(path: JsonNode;
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
  var valid_603262 = query.getOrDefault("Action")
  valid_603262 = validateParameter(valid_603262, JString, required = true, default = newJString(
      "DescribeAvailabilityOptions"))
  if valid_603262 != nil:
    section.add "Action", valid_603262
  var valid_603263 = query.getOrDefault("Version")
  valid_603263 = validateParameter(valid_603263, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_603263 != nil:
    section.add "Version", valid_603263
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
  var valid_603264 = header.getOrDefault("X-Amz-Date")
  valid_603264 = validateParameter(valid_603264, JString, required = false,
                                 default = nil)
  if valid_603264 != nil:
    section.add "X-Amz-Date", valid_603264
  var valid_603265 = header.getOrDefault("X-Amz-Security-Token")
  valid_603265 = validateParameter(valid_603265, JString, required = false,
                                 default = nil)
  if valid_603265 != nil:
    section.add "X-Amz-Security-Token", valid_603265
  var valid_603266 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603266 = validateParameter(valid_603266, JString, required = false,
                                 default = nil)
  if valid_603266 != nil:
    section.add "X-Amz-Content-Sha256", valid_603266
  var valid_603267 = header.getOrDefault("X-Amz-Algorithm")
  valid_603267 = validateParameter(valid_603267, JString, required = false,
                                 default = nil)
  if valid_603267 != nil:
    section.add "X-Amz-Algorithm", valid_603267
  var valid_603268 = header.getOrDefault("X-Amz-Signature")
  valid_603268 = validateParameter(valid_603268, JString, required = false,
                                 default = nil)
  if valid_603268 != nil:
    section.add "X-Amz-Signature", valid_603268
  var valid_603269 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603269 = validateParameter(valid_603269, JString, required = false,
                                 default = nil)
  if valid_603269 != nil:
    section.add "X-Amz-SignedHeaders", valid_603269
  var valid_603270 = header.getOrDefault("X-Amz-Credential")
  valid_603270 = validateParameter(valid_603270, JString, required = false,
                                 default = nil)
  if valid_603270 != nil:
    section.add "X-Amz-Credential", valid_603270
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_603271 = formData.getOrDefault("DomainName")
  valid_603271 = validateParameter(valid_603271, JString, required = true,
                                 default = nil)
  if valid_603271 != nil:
    section.add "DomainName", valid_603271
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603272: Call_PostDescribeAvailabilityOptions_603259;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_603272.validator(path, query, header, formData, body)
  let scheme = call_603272.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603272.url(scheme.get, call_603272.host, call_603272.base,
                         call_603272.route, valid.getOrDefault("path"))
  result = hook(call_603272, url, valid)

proc call*(call_603273: Call_PostDescribeAvailabilityOptions_603259;
          DomainName: string; Action: string = "DescribeAvailabilityOptions";
          Version: string = "2011-02-01"): Recallable =
  ## postDescribeAvailabilityOptions
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603274 = newJObject()
  var formData_603275 = newJObject()
  add(formData_603275, "DomainName", newJString(DomainName))
  add(query_603274, "Action", newJString(Action))
  add(query_603274, "Version", newJString(Version))
  result = call_603273.call(nil, query_603274, nil, formData_603275, nil)

var postDescribeAvailabilityOptions* = Call_PostDescribeAvailabilityOptions_603259(
    name: "postDescribeAvailabilityOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeAvailabilityOptions",
    validator: validate_PostDescribeAvailabilityOptions_603260, base: "/",
    url: url_PostDescribeAvailabilityOptions_603261,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAvailabilityOptions_603243 = ref object of OpenApiRestCall_602433
proc url_GetDescribeAvailabilityOptions_603245(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeAvailabilityOptions_603244(path: JsonNode;
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
  var valid_603246 = query.getOrDefault("Action")
  valid_603246 = validateParameter(valid_603246, JString, required = true, default = newJString(
      "DescribeAvailabilityOptions"))
  if valid_603246 != nil:
    section.add "Action", valid_603246
  var valid_603247 = query.getOrDefault("DomainName")
  valid_603247 = validateParameter(valid_603247, JString, required = true,
                                 default = nil)
  if valid_603247 != nil:
    section.add "DomainName", valid_603247
  var valid_603248 = query.getOrDefault("Version")
  valid_603248 = validateParameter(valid_603248, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_603248 != nil:
    section.add "Version", valid_603248
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
  var valid_603249 = header.getOrDefault("X-Amz-Date")
  valid_603249 = validateParameter(valid_603249, JString, required = false,
                                 default = nil)
  if valid_603249 != nil:
    section.add "X-Amz-Date", valid_603249
  var valid_603250 = header.getOrDefault("X-Amz-Security-Token")
  valid_603250 = validateParameter(valid_603250, JString, required = false,
                                 default = nil)
  if valid_603250 != nil:
    section.add "X-Amz-Security-Token", valid_603250
  var valid_603251 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603251 = validateParameter(valid_603251, JString, required = false,
                                 default = nil)
  if valid_603251 != nil:
    section.add "X-Amz-Content-Sha256", valid_603251
  var valid_603252 = header.getOrDefault("X-Amz-Algorithm")
  valid_603252 = validateParameter(valid_603252, JString, required = false,
                                 default = nil)
  if valid_603252 != nil:
    section.add "X-Amz-Algorithm", valid_603252
  var valid_603253 = header.getOrDefault("X-Amz-Signature")
  valid_603253 = validateParameter(valid_603253, JString, required = false,
                                 default = nil)
  if valid_603253 != nil:
    section.add "X-Amz-Signature", valid_603253
  var valid_603254 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603254 = validateParameter(valid_603254, JString, required = false,
                                 default = nil)
  if valid_603254 != nil:
    section.add "X-Amz-SignedHeaders", valid_603254
  var valid_603255 = header.getOrDefault("X-Amz-Credential")
  valid_603255 = validateParameter(valid_603255, JString, required = false,
                                 default = nil)
  if valid_603255 != nil:
    section.add "X-Amz-Credential", valid_603255
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603256: Call_GetDescribeAvailabilityOptions_603243; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_603256.validator(path, query, header, formData, body)
  let scheme = call_603256.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603256.url(scheme.get, call_603256.host, call_603256.base,
                         call_603256.route, valid.getOrDefault("path"))
  result = hook(call_603256, url, valid)

proc call*(call_603257: Call_GetDescribeAvailabilityOptions_603243;
          DomainName: string; Action: string = "DescribeAvailabilityOptions";
          Version: string = "2011-02-01"): Recallable =
  ## getDescribeAvailabilityOptions
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_603258 = newJObject()
  add(query_603258, "Action", newJString(Action))
  add(query_603258, "DomainName", newJString(DomainName))
  add(query_603258, "Version", newJString(Version))
  result = call_603257.call(nil, query_603258, nil, nil, nil)

var getDescribeAvailabilityOptions* = Call_GetDescribeAvailabilityOptions_603243(
    name: "getDescribeAvailabilityOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeAvailabilityOptions",
    validator: validate_GetDescribeAvailabilityOptions_603244, base: "/",
    url: url_GetDescribeAvailabilityOptions_603245,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDefaultSearchField_603292 = ref object of OpenApiRestCall_602433
proc url_PostDescribeDefaultSearchField_603294(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDefaultSearchField_603293(path: JsonNode;
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
  var valid_603295 = query.getOrDefault("Action")
  valid_603295 = validateParameter(valid_603295, JString, required = true, default = newJString(
      "DescribeDefaultSearchField"))
  if valid_603295 != nil:
    section.add "Action", valid_603295
  var valid_603296 = query.getOrDefault("Version")
  valid_603296 = validateParameter(valid_603296, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_603296 != nil:
    section.add "Version", valid_603296
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
  var valid_603297 = header.getOrDefault("X-Amz-Date")
  valid_603297 = validateParameter(valid_603297, JString, required = false,
                                 default = nil)
  if valid_603297 != nil:
    section.add "X-Amz-Date", valid_603297
  var valid_603298 = header.getOrDefault("X-Amz-Security-Token")
  valid_603298 = validateParameter(valid_603298, JString, required = false,
                                 default = nil)
  if valid_603298 != nil:
    section.add "X-Amz-Security-Token", valid_603298
  var valid_603299 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603299 = validateParameter(valid_603299, JString, required = false,
                                 default = nil)
  if valid_603299 != nil:
    section.add "X-Amz-Content-Sha256", valid_603299
  var valid_603300 = header.getOrDefault("X-Amz-Algorithm")
  valid_603300 = validateParameter(valid_603300, JString, required = false,
                                 default = nil)
  if valid_603300 != nil:
    section.add "X-Amz-Algorithm", valid_603300
  var valid_603301 = header.getOrDefault("X-Amz-Signature")
  valid_603301 = validateParameter(valid_603301, JString, required = false,
                                 default = nil)
  if valid_603301 != nil:
    section.add "X-Amz-Signature", valid_603301
  var valid_603302 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603302 = validateParameter(valid_603302, JString, required = false,
                                 default = nil)
  if valid_603302 != nil:
    section.add "X-Amz-SignedHeaders", valid_603302
  var valid_603303 = header.getOrDefault("X-Amz-Credential")
  valid_603303 = validateParameter(valid_603303, JString, required = false,
                                 default = nil)
  if valid_603303 != nil:
    section.add "X-Amz-Credential", valid_603303
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_603304 = formData.getOrDefault("DomainName")
  valid_603304 = validateParameter(valid_603304, JString, required = true,
                                 default = nil)
  if valid_603304 != nil:
    section.add "DomainName", valid_603304
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603305: Call_PostDescribeDefaultSearchField_603292; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the default search field configured for the search domain.
  ## 
  let valid = call_603305.validator(path, query, header, formData, body)
  let scheme = call_603305.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603305.url(scheme.get, call_603305.host, call_603305.base,
                         call_603305.route, valid.getOrDefault("path"))
  result = hook(call_603305, url, valid)

proc call*(call_603306: Call_PostDescribeDefaultSearchField_603292;
          DomainName: string; Action: string = "DescribeDefaultSearchField";
          Version: string = "2011-02-01"): Recallable =
  ## postDescribeDefaultSearchField
  ## Gets the default search field configured for the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603307 = newJObject()
  var formData_603308 = newJObject()
  add(formData_603308, "DomainName", newJString(DomainName))
  add(query_603307, "Action", newJString(Action))
  add(query_603307, "Version", newJString(Version))
  result = call_603306.call(nil, query_603307, nil, formData_603308, nil)

var postDescribeDefaultSearchField* = Call_PostDescribeDefaultSearchField_603292(
    name: "postDescribeDefaultSearchField", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeDefaultSearchField",
    validator: validate_PostDescribeDefaultSearchField_603293, base: "/",
    url: url_PostDescribeDefaultSearchField_603294,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDefaultSearchField_603276 = ref object of OpenApiRestCall_602433
proc url_GetDescribeDefaultSearchField_603278(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDefaultSearchField_603277(path: JsonNode; query: JsonNode;
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
  var valid_603279 = query.getOrDefault("Action")
  valid_603279 = validateParameter(valid_603279, JString, required = true, default = newJString(
      "DescribeDefaultSearchField"))
  if valid_603279 != nil:
    section.add "Action", valid_603279
  var valid_603280 = query.getOrDefault("DomainName")
  valid_603280 = validateParameter(valid_603280, JString, required = true,
                                 default = nil)
  if valid_603280 != nil:
    section.add "DomainName", valid_603280
  var valid_603281 = query.getOrDefault("Version")
  valid_603281 = validateParameter(valid_603281, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_603281 != nil:
    section.add "Version", valid_603281
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
  var valid_603282 = header.getOrDefault("X-Amz-Date")
  valid_603282 = validateParameter(valid_603282, JString, required = false,
                                 default = nil)
  if valid_603282 != nil:
    section.add "X-Amz-Date", valid_603282
  var valid_603283 = header.getOrDefault("X-Amz-Security-Token")
  valid_603283 = validateParameter(valid_603283, JString, required = false,
                                 default = nil)
  if valid_603283 != nil:
    section.add "X-Amz-Security-Token", valid_603283
  var valid_603284 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603284 = validateParameter(valid_603284, JString, required = false,
                                 default = nil)
  if valid_603284 != nil:
    section.add "X-Amz-Content-Sha256", valid_603284
  var valid_603285 = header.getOrDefault("X-Amz-Algorithm")
  valid_603285 = validateParameter(valid_603285, JString, required = false,
                                 default = nil)
  if valid_603285 != nil:
    section.add "X-Amz-Algorithm", valid_603285
  var valid_603286 = header.getOrDefault("X-Amz-Signature")
  valid_603286 = validateParameter(valid_603286, JString, required = false,
                                 default = nil)
  if valid_603286 != nil:
    section.add "X-Amz-Signature", valid_603286
  var valid_603287 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603287 = validateParameter(valid_603287, JString, required = false,
                                 default = nil)
  if valid_603287 != nil:
    section.add "X-Amz-SignedHeaders", valid_603287
  var valid_603288 = header.getOrDefault("X-Amz-Credential")
  valid_603288 = validateParameter(valid_603288, JString, required = false,
                                 default = nil)
  if valid_603288 != nil:
    section.add "X-Amz-Credential", valid_603288
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603289: Call_GetDescribeDefaultSearchField_603276; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the default search field configured for the search domain.
  ## 
  let valid = call_603289.validator(path, query, header, formData, body)
  let scheme = call_603289.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603289.url(scheme.get, call_603289.host, call_603289.base,
                         call_603289.route, valid.getOrDefault("path"))
  result = hook(call_603289, url, valid)

proc call*(call_603290: Call_GetDescribeDefaultSearchField_603276;
          DomainName: string; Action: string = "DescribeDefaultSearchField";
          Version: string = "2011-02-01"): Recallable =
  ## getDescribeDefaultSearchField
  ## Gets the default search field configured for the search domain.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_603291 = newJObject()
  add(query_603291, "Action", newJString(Action))
  add(query_603291, "DomainName", newJString(DomainName))
  add(query_603291, "Version", newJString(Version))
  result = call_603290.call(nil, query_603291, nil, nil, nil)

var getDescribeDefaultSearchField* = Call_GetDescribeDefaultSearchField_603276(
    name: "getDescribeDefaultSearchField", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeDefaultSearchField",
    validator: validate_GetDescribeDefaultSearchField_603277, base: "/",
    url: url_GetDescribeDefaultSearchField_603278,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDomains_603325 = ref object of OpenApiRestCall_602433
proc url_PostDescribeDomains_603327(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDomains_603326(path: JsonNode; query: JsonNode;
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
  var valid_603328 = query.getOrDefault("Action")
  valid_603328 = validateParameter(valid_603328, JString, required = true,
                                 default = newJString("DescribeDomains"))
  if valid_603328 != nil:
    section.add "Action", valid_603328
  var valid_603329 = query.getOrDefault("Version")
  valid_603329 = validateParameter(valid_603329, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_603329 != nil:
    section.add "Version", valid_603329
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
  var valid_603330 = header.getOrDefault("X-Amz-Date")
  valid_603330 = validateParameter(valid_603330, JString, required = false,
                                 default = nil)
  if valid_603330 != nil:
    section.add "X-Amz-Date", valid_603330
  var valid_603331 = header.getOrDefault("X-Amz-Security-Token")
  valid_603331 = validateParameter(valid_603331, JString, required = false,
                                 default = nil)
  if valid_603331 != nil:
    section.add "X-Amz-Security-Token", valid_603331
  var valid_603332 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603332 = validateParameter(valid_603332, JString, required = false,
                                 default = nil)
  if valid_603332 != nil:
    section.add "X-Amz-Content-Sha256", valid_603332
  var valid_603333 = header.getOrDefault("X-Amz-Algorithm")
  valid_603333 = validateParameter(valid_603333, JString, required = false,
                                 default = nil)
  if valid_603333 != nil:
    section.add "X-Amz-Algorithm", valid_603333
  var valid_603334 = header.getOrDefault("X-Amz-Signature")
  valid_603334 = validateParameter(valid_603334, JString, required = false,
                                 default = nil)
  if valid_603334 != nil:
    section.add "X-Amz-Signature", valid_603334
  var valid_603335 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603335 = validateParameter(valid_603335, JString, required = false,
                                 default = nil)
  if valid_603335 != nil:
    section.add "X-Amz-SignedHeaders", valid_603335
  var valid_603336 = header.getOrDefault("X-Amz-Credential")
  valid_603336 = validateParameter(valid_603336, JString, required = false,
                                 default = nil)
  if valid_603336 != nil:
    section.add "X-Amz-Credential", valid_603336
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainNames: JArray
  ##              : A list of domain names.
  section = newJObject()
  var valid_603337 = formData.getOrDefault("DomainNames")
  valid_603337 = validateParameter(valid_603337, JArray, required = false,
                                 default = nil)
  if valid_603337 != nil:
    section.add "DomainNames", valid_603337
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603338: Call_PostDescribeDomains_603325; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default.
  ## 
  let valid = call_603338.validator(path, query, header, formData, body)
  let scheme = call_603338.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603338.url(scheme.get, call_603338.host, call_603338.base,
                         call_603338.route, valid.getOrDefault("path"))
  result = hook(call_603338, url, valid)

proc call*(call_603339: Call_PostDescribeDomains_603325;
          DomainNames: JsonNode = nil; Action: string = "DescribeDomains";
          Version: string = "2011-02-01"): Recallable =
  ## postDescribeDomains
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default.
  ##   DomainNames: JArray
  ##              : A list of domain names.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603340 = newJObject()
  var formData_603341 = newJObject()
  if DomainNames != nil:
    formData_603341.add "DomainNames", DomainNames
  add(query_603340, "Action", newJString(Action))
  add(query_603340, "Version", newJString(Version))
  result = call_603339.call(nil, query_603340, nil, formData_603341, nil)

var postDescribeDomains* = Call_PostDescribeDomains_603325(
    name: "postDescribeDomains", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeDomains",
    validator: validate_PostDescribeDomains_603326, base: "/",
    url: url_PostDescribeDomains_603327, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDomains_603309 = ref object of OpenApiRestCall_602433
proc url_GetDescribeDomains_603311(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDomains_603310(path: JsonNode; query: JsonNode;
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
  var valid_603312 = query.getOrDefault("DomainNames")
  valid_603312 = validateParameter(valid_603312, JArray, required = false,
                                 default = nil)
  if valid_603312 != nil:
    section.add "DomainNames", valid_603312
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603313 = query.getOrDefault("Action")
  valid_603313 = validateParameter(valid_603313, JString, required = true,
                                 default = newJString("DescribeDomains"))
  if valid_603313 != nil:
    section.add "Action", valid_603313
  var valid_603314 = query.getOrDefault("Version")
  valid_603314 = validateParameter(valid_603314, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_603314 != nil:
    section.add "Version", valid_603314
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
  var valid_603315 = header.getOrDefault("X-Amz-Date")
  valid_603315 = validateParameter(valid_603315, JString, required = false,
                                 default = nil)
  if valid_603315 != nil:
    section.add "X-Amz-Date", valid_603315
  var valid_603316 = header.getOrDefault("X-Amz-Security-Token")
  valid_603316 = validateParameter(valid_603316, JString, required = false,
                                 default = nil)
  if valid_603316 != nil:
    section.add "X-Amz-Security-Token", valid_603316
  var valid_603317 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603317 = validateParameter(valid_603317, JString, required = false,
                                 default = nil)
  if valid_603317 != nil:
    section.add "X-Amz-Content-Sha256", valid_603317
  var valid_603318 = header.getOrDefault("X-Amz-Algorithm")
  valid_603318 = validateParameter(valid_603318, JString, required = false,
                                 default = nil)
  if valid_603318 != nil:
    section.add "X-Amz-Algorithm", valid_603318
  var valid_603319 = header.getOrDefault("X-Amz-Signature")
  valid_603319 = validateParameter(valid_603319, JString, required = false,
                                 default = nil)
  if valid_603319 != nil:
    section.add "X-Amz-Signature", valid_603319
  var valid_603320 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603320 = validateParameter(valid_603320, JString, required = false,
                                 default = nil)
  if valid_603320 != nil:
    section.add "X-Amz-SignedHeaders", valid_603320
  var valid_603321 = header.getOrDefault("X-Amz-Credential")
  valid_603321 = validateParameter(valid_603321, JString, required = false,
                                 default = nil)
  if valid_603321 != nil:
    section.add "X-Amz-Credential", valid_603321
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603322: Call_GetDescribeDomains_603309; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default.
  ## 
  let valid = call_603322.validator(path, query, header, formData, body)
  let scheme = call_603322.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603322.url(scheme.get, call_603322.host, call_603322.base,
                         call_603322.route, valid.getOrDefault("path"))
  result = hook(call_603322, url, valid)

proc call*(call_603323: Call_GetDescribeDomains_603309;
          DomainNames: JsonNode = nil; Action: string = "DescribeDomains";
          Version: string = "2011-02-01"): Recallable =
  ## getDescribeDomains
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default.
  ##   DomainNames: JArray
  ##              : A list of domain names.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603324 = newJObject()
  if DomainNames != nil:
    query_603324.add "DomainNames", DomainNames
  add(query_603324, "Action", newJString(Action))
  add(query_603324, "Version", newJString(Version))
  result = call_603323.call(nil, query_603324, nil, nil, nil)

var getDescribeDomains* = Call_GetDescribeDomains_603309(
    name: "getDescribeDomains", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeDomains",
    validator: validate_GetDescribeDomains_603310, base: "/",
    url: url_GetDescribeDomains_603311, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeIndexFields_603359 = ref object of OpenApiRestCall_602433
proc url_PostDescribeIndexFields_603361(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeIndexFields_603360(path: JsonNode; query: JsonNode;
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
  var valid_603362 = query.getOrDefault("Action")
  valid_603362 = validateParameter(valid_603362, JString, required = true,
                                 default = newJString("DescribeIndexFields"))
  if valid_603362 != nil:
    section.add "Action", valid_603362
  var valid_603363 = query.getOrDefault("Version")
  valid_603363 = validateParameter(valid_603363, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_603363 != nil:
    section.add "Version", valid_603363
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
  var valid_603364 = header.getOrDefault("X-Amz-Date")
  valid_603364 = validateParameter(valid_603364, JString, required = false,
                                 default = nil)
  if valid_603364 != nil:
    section.add "X-Amz-Date", valid_603364
  var valid_603365 = header.getOrDefault("X-Amz-Security-Token")
  valid_603365 = validateParameter(valid_603365, JString, required = false,
                                 default = nil)
  if valid_603365 != nil:
    section.add "X-Amz-Security-Token", valid_603365
  var valid_603366 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603366 = validateParameter(valid_603366, JString, required = false,
                                 default = nil)
  if valid_603366 != nil:
    section.add "X-Amz-Content-Sha256", valid_603366
  var valid_603367 = header.getOrDefault("X-Amz-Algorithm")
  valid_603367 = validateParameter(valid_603367, JString, required = false,
                                 default = nil)
  if valid_603367 != nil:
    section.add "X-Amz-Algorithm", valid_603367
  var valid_603368 = header.getOrDefault("X-Amz-Signature")
  valid_603368 = validateParameter(valid_603368, JString, required = false,
                                 default = nil)
  if valid_603368 != nil:
    section.add "X-Amz-Signature", valid_603368
  var valid_603369 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603369 = validateParameter(valid_603369, JString, required = false,
                                 default = nil)
  if valid_603369 != nil:
    section.add "X-Amz-SignedHeaders", valid_603369
  var valid_603370 = header.getOrDefault("X-Amz-Credential")
  valid_603370 = validateParameter(valid_603370, JString, required = false,
                                 default = nil)
  if valid_603370 != nil:
    section.add "X-Amz-Credential", valid_603370
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   FieldNames: JArray
  ##             : Limits the <code>DescribeIndexFields</code> response to the specified fields.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_603371 = formData.getOrDefault("DomainName")
  valid_603371 = validateParameter(valid_603371, JString, required = true,
                                 default = nil)
  if valid_603371 != nil:
    section.add "DomainName", valid_603371
  var valid_603372 = formData.getOrDefault("FieldNames")
  valid_603372 = validateParameter(valid_603372, JArray, required = false,
                                 default = nil)
  if valid_603372 != nil:
    section.add "FieldNames", valid_603372
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603373: Call_PostDescribeIndexFields_603359; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. Shows all fields by default.
  ## 
  let valid = call_603373.validator(path, query, header, formData, body)
  let scheme = call_603373.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603373.url(scheme.get, call_603373.host, call_603373.base,
                         call_603373.route, valid.getOrDefault("path"))
  result = hook(call_603373, url, valid)

proc call*(call_603374: Call_PostDescribeIndexFields_603359; DomainName: string;
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
  var query_603375 = newJObject()
  var formData_603376 = newJObject()
  add(formData_603376, "DomainName", newJString(DomainName))
  add(query_603375, "Action", newJString(Action))
  if FieldNames != nil:
    formData_603376.add "FieldNames", FieldNames
  add(query_603375, "Version", newJString(Version))
  result = call_603374.call(nil, query_603375, nil, formData_603376, nil)

var postDescribeIndexFields* = Call_PostDescribeIndexFields_603359(
    name: "postDescribeIndexFields", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeIndexFields",
    validator: validate_PostDescribeIndexFields_603360, base: "/",
    url: url_PostDescribeIndexFields_603361, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeIndexFields_603342 = ref object of OpenApiRestCall_602433
proc url_GetDescribeIndexFields_603344(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeIndexFields_603343(path: JsonNode; query: JsonNode;
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
  var valid_603345 = query.getOrDefault("FieldNames")
  valid_603345 = validateParameter(valid_603345, JArray, required = false,
                                 default = nil)
  if valid_603345 != nil:
    section.add "FieldNames", valid_603345
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603346 = query.getOrDefault("Action")
  valid_603346 = validateParameter(valid_603346, JString, required = true,
                                 default = newJString("DescribeIndexFields"))
  if valid_603346 != nil:
    section.add "Action", valid_603346
  var valid_603347 = query.getOrDefault("DomainName")
  valid_603347 = validateParameter(valid_603347, JString, required = true,
                                 default = nil)
  if valid_603347 != nil:
    section.add "DomainName", valid_603347
  var valid_603348 = query.getOrDefault("Version")
  valid_603348 = validateParameter(valid_603348, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_603348 != nil:
    section.add "Version", valid_603348
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
  var valid_603349 = header.getOrDefault("X-Amz-Date")
  valid_603349 = validateParameter(valid_603349, JString, required = false,
                                 default = nil)
  if valid_603349 != nil:
    section.add "X-Amz-Date", valid_603349
  var valid_603350 = header.getOrDefault("X-Amz-Security-Token")
  valid_603350 = validateParameter(valid_603350, JString, required = false,
                                 default = nil)
  if valid_603350 != nil:
    section.add "X-Amz-Security-Token", valid_603350
  var valid_603351 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603351 = validateParameter(valid_603351, JString, required = false,
                                 default = nil)
  if valid_603351 != nil:
    section.add "X-Amz-Content-Sha256", valid_603351
  var valid_603352 = header.getOrDefault("X-Amz-Algorithm")
  valid_603352 = validateParameter(valid_603352, JString, required = false,
                                 default = nil)
  if valid_603352 != nil:
    section.add "X-Amz-Algorithm", valid_603352
  var valid_603353 = header.getOrDefault("X-Amz-Signature")
  valid_603353 = validateParameter(valid_603353, JString, required = false,
                                 default = nil)
  if valid_603353 != nil:
    section.add "X-Amz-Signature", valid_603353
  var valid_603354 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603354 = validateParameter(valid_603354, JString, required = false,
                                 default = nil)
  if valid_603354 != nil:
    section.add "X-Amz-SignedHeaders", valid_603354
  var valid_603355 = header.getOrDefault("X-Amz-Credential")
  valid_603355 = validateParameter(valid_603355, JString, required = false,
                                 default = nil)
  if valid_603355 != nil:
    section.add "X-Amz-Credential", valid_603355
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603356: Call_GetDescribeIndexFields_603342; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. Shows all fields by default.
  ## 
  let valid = call_603356.validator(path, query, header, formData, body)
  let scheme = call_603356.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603356.url(scheme.get, call_603356.host, call_603356.base,
                         call_603356.route, valid.getOrDefault("path"))
  result = hook(call_603356, url, valid)

proc call*(call_603357: Call_GetDescribeIndexFields_603342; DomainName: string;
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
  var query_603358 = newJObject()
  if FieldNames != nil:
    query_603358.add "FieldNames", FieldNames
  add(query_603358, "Action", newJString(Action))
  add(query_603358, "DomainName", newJString(DomainName))
  add(query_603358, "Version", newJString(Version))
  result = call_603357.call(nil, query_603358, nil, nil, nil)

var getDescribeIndexFields* = Call_GetDescribeIndexFields_603342(
    name: "getDescribeIndexFields", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeIndexFields",
    validator: validate_GetDescribeIndexFields_603343, base: "/",
    url: url_GetDescribeIndexFields_603344, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeRankExpressions_603394 = ref object of OpenApiRestCall_602433
proc url_PostDescribeRankExpressions_603396(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeRankExpressions_603395(path: JsonNode; query: JsonNode;
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
  var valid_603397 = query.getOrDefault("Action")
  valid_603397 = validateParameter(valid_603397, JString, required = true, default = newJString(
      "DescribeRankExpressions"))
  if valid_603397 != nil:
    section.add "Action", valid_603397
  var valid_603398 = query.getOrDefault("Version")
  valid_603398 = validateParameter(valid_603398, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_603398 != nil:
    section.add "Version", valid_603398
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
  var valid_603399 = header.getOrDefault("X-Amz-Date")
  valid_603399 = validateParameter(valid_603399, JString, required = false,
                                 default = nil)
  if valid_603399 != nil:
    section.add "X-Amz-Date", valid_603399
  var valid_603400 = header.getOrDefault("X-Amz-Security-Token")
  valid_603400 = validateParameter(valid_603400, JString, required = false,
                                 default = nil)
  if valid_603400 != nil:
    section.add "X-Amz-Security-Token", valid_603400
  var valid_603401 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603401 = validateParameter(valid_603401, JString, required = false,
                                 default = nil)
  if valid_603401 != nil:
    section.add "X-Amz-Content-Sha256", valid_603401
  var valid_603402 = header.getOrDefault("X-Amz-Algorithm")
  valid_603402 = validateParameter(valid_603402, JString, required = false,
                                 default = nil)
  if valid_603402 != nil:
    section.add "X-Amz-Algorithm", valid_603402
  var valid_603403 = header.getOrDefault("X-Amz-Signature")
  valid_603403 = validateParameter(valid_603403, JString, required = false,
                                 default = nil)
  if valid_603403 != nil:
    section.add "X-Amz-Signature", valid_603403
  var valid_603404 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603404 = validateParameter(valid_603404, JString, required = false,
                                 default = nil)
  if valid_603404 != nil:
    section.add "X-Amz-SignedHeaders", valid_603404
  var valid_603405 = header.getOrDefault("X-Amz-Credential")
  valid_603405 = validateParameter(valid_603405, JString, required = false,
                                 default = nil)
  if valid_603405 != nil:
    section.add "X-Amz-Credential", valid_603405
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   RankNames: JArray
  ##            : Limits the <code>DescribeRankExpressions</code> response to the specified fields.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_603406 = formData.getOrDefault("DomainName")
  valid_603406 = validateParameter(valid_603406, JString, required = true,
                                 default = nil)
  if valid_603406 != nil:
    section.add "DomainName", valid_603406
  var valid_603407 = formData.getOrDefault("RankNames")
  valid_603407 = validateParameter(valid_603407, JArray, required = false,
                                 default = nil)
  if valid_603407 != nil:
    section.add "RankNames", valid_603407
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603408: Call_PostDescribeRankExpressions_603394; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the rank expressions configured for the search domain. Can be limited to specific rank expressions by name. Shows all rank expressions by default. 
  ## 
  let valid = call_603408.validator(path, query, header, formData, body)
  let scheme = call_603408.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603408.url(scheme.get, call_603408.host, call_603408.base,
                         call_603408.route, valid.getOrDefault("path"))
  result = hook(call_603408, url, valid)

proc call*(call_603409: Call_PostDescribeRankExpressions_603394;
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
  var query_603410 = newJObject()
  var formData_603411 = newJObject()
  add(formData_603411, "DomainName", newJString(DomainName))
  add(query_603410, "Action", newJString(Action))
  if RankNames != nil:
    formData_603411.add "RankNames", RankNames
  add(query_603410, "Version", newJString(Version))
  result = call_603409.call(nil, query_603410, nil, formData_603411, nil)

var postDescribeRankExpressions* = Call_PostDescribeRankExpressions_603394(
    name: "postDescribeRankExpressions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeRankExpressions",
    validator: validate_PostDescribeRankExpressions_603395, base: "/",
    url: url_PostDescribeRankExpressions_603396,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeRankExpressions_603377 = ref object of OpenApiRestCall_602433
proc url_GetDescribeRankExpressions_603379(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeRankExpressions_603378(path: JsonNode; query: JsonNode;
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
  var valid_603380 = query.getOrDefault("RankNames")
  valid_603380 = validateParameter(valid_603380, JArray, required = false,
                                 default = nil)
  if valid_603380 != nil:
    section.add "RankNames", valid_603380
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_603381 = query.getOrDefault("Action")
  valid_603381 = validateParameter(valid_603381, JString, required = true, default = newJString(
      "DescribeRankExpressions"))
  if valid_603381 != nil:
    section.add "Action", valid_603381
  var valid_603382 = query.getOrDefault("DomainName")
  valid_603382 = validateParameter(valid_603382, JString, required = true,
                                 default = nil)
  if valid_603382 != nil:
    section.add "DomainName", valid_603382
  var valid_603383 = query.getOrDefault("Version")
  valid_603383 = validateParameter(valid_603383, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_603383 != nil:
    section.add "Version", valid_603383
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
  var valid_603384 = header.getOrDefault("X-Amz-Date")
  valid_603384 = validateParameter(valid_603384, JString, required = false,
                                 default = nil)
  if valid_603384 != nil:
    section.add "X-Amz-Date", valid_603384
  var valid_603385 = header.getOrDefault("X-Amz-Security-Token")
  valid_603385 = validateParameter(valid_603385, JString, required = false,
                                 default = nil)
  if valid_603385 != nil:
    section.add "X-Amz-Security-Token", valid_603385
  var valid_603386 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603386 = validateParameter(valid_603386, JString, required = false,
                                 default = nil)
  if valid_603386 != nil:
    section.add "X-Amz-Content-Sha256", valid_603386
  var valid_603387 = header.getOrDefault("X-Amz-Algorithm")
  valid_603387 = validateParameter(valid_603387, JString, required = false,
                                 default = nil)
  if valid_603387 != nil:
    section.add "X-Amz-Algorithm", valid_603387
  var valid_603388 = header.getOrDefault("X-Amz-Signature")
  valid_603388 = validateParameter(valid_603388, JString, required = false,
                                 default = nil)
  if valid_603388 != nil:
    section.add "X-Amz-Signature", valid_603388
  var valid_603389 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603389 = validateParameter(valid_603389, JString, required = false,
                                 default = nil)
  if valid_603389 != nil:
    section.add "X-Amz-SignedHeaders", valid_603389
  var valid_603390 = header.getOrDefault("X-Amz-Credential")
  valid_603390 = validateParameter(valid_603390, JString, required = false,
                                 default = nil)
  if valid_603390 != nil:
    section.add "X-Amz-Credential", valid_603390
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603391: Call_GetDescribeRankExpressions_603377; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the rank expressions configured for the search domain. Can be limited to specific rank expressions by name. Shows all rank expressions by default. 
  ## 
  let valid = call_603391.validator(path, query, header, formData, body)
  let scheme = call_603391.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603391.url(scheme.get, call_603391.host, call_603391.base,
                         call_603391.route, valid.getOrDefault("path"))
  result = hook(call_603391, url, valid)

proc call*(call_603392: Call_GetDescribeRankExpressions_603377; DomainName: string;
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
  var query_603393 = newJObject()
  if RankNames != nil:
    query_603393.add "RankNames", RankNames
  add(query_603393, "Action", newJString(Action))
  add(query_603393, "DomainName", newJString(DomainName))
  add(query_603393, "Version", newJString(Version))
  result = call_603392.call(nil, query_603393, nil, nil, nil)

var getDescribeRankExpressions* = Call_GetDescribeRankExpressions_603377(
    name: "getDescribeRankExpressions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeRankExpressions",
    validator: validate_GetDescribeRankExpressions_603378, base: "/",
    url: url_GetDescribeRankExpressions_603379,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeServiceAccessPolicies_603428 = ref object of OpenApiRestCall_602433
proc url_PostDescribeServiceAccessPolicies_603430(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeServiceAccessPolicies_603429(path: JsonNode;
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
  var valid_603431 = query.getOrDefault("Action")
  valid_603431 = validateParameter(valid_603431, JString, required = true, default = newJString(
      "DescribeServiceAccessPolicies"))
  if valid_603431 != nil:
    section.add "Action", valid_603431
  var valid_603432 = query.getOrDefault("Version")
  valid_603432 = validateParameter(valid_603432, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_603432 != nil:
    section.add "Version", valid_603432
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
  var valid_603433 = header.getOrDefault("X-Amz-Date")
  valid_603433 = validateParameter(valid_603433, JString, required = false,
                                 default = nil)
  if valid_603433 != nil:
    section.add "X-Amz-Date", valid_603433
  var valid_603434 = header.getOrDefault("X-Amz-Security-Token")
  valid_603434 = validateParameter(valid_603434, JString, required = false,
                                 default = nil)
  if valid_603434 != nil:
    section.add "X-Amz-Security-Token", valid_603434
  var valid_603435 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603435 = validateParameter(valid_603435, JString, required = false,
                                 default = nil)
  if valid_603435 != nil:
    section.add "X-Amz-Content-Sha256", valid_603435
  var valid_603436 = header.getOrDefault("X-Amz-Algorithm")
  valid_603436 = validateParameter(valid_603436, JString, required = false,
                                 default = nil)
  if valid_603436 != nil:
    section.add "X-Amz-Algorithm", valid_603436
  var valid_603437 = header.getOrDefault("X-Amz-Signature")
  valid_603437 = validateParameter(valid_603437, JString, required = false,
                                 default = nil)
  if valid_603437 != nil:
    section.add "X-Amz-Signature", valid_603437
  var valid_603438 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603438 = validateParameter(valid_603438, JString, required = false,
                                 default = nil)
  if valid_603438 != nil:
    section.add "X-Amz-SignedHeaders", valid_603438
  var valid_603439 = header.getOrDefault("X-Amz-Credential")
  valid_603439 = validateParameter(valid_603439, JString, required = false,
                                 default = nil)
  if valid_603439 != nil:
    section.add "X-Amz-Credential", valid_603439
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_603440 = formData.getOrDefault("DomainName")
  valid_603440 = validateParameter(valid_603440, JString, required = true,
                                 default = nil)
  if valid_603440 != nil:
    section.add "DomainName", valid_603440
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603441: Call_PostDescribeServiceAccessPolicies_603428;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets information about the resource-based policies that control access to the domain's document and search services.
  ## 
  let valid = call_603441.validator(path, query, header, formData, body)
  let scheme = call_603441.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603441.url(scheme.get, call_603441.host, call_603441.base,
                         call_603441.route, valid.getOrDefault("path"))
  result = hook(call_603441, url, valid)

proc call*(call_603442: Call_PostDescribeServiceAccessPolicies_603428;
          DomainName: string; Action: string = "DescribeServiceAccessPolicies";
          Version: string = "2011-02-01"): Recallable =
  ## postDescribeServiceAccessPolicies
  ## Gets information about the resource-based policies that control access to the domain's document and search services.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603443 = newJObject()
  var formData_603444 = newJObject()
  add(formData_603444, "DomainName", newJString(DomainName))
  add(query_603443, "Action", newJString(Action))
  add(query_603443, "Version", newJString(Version))
  result = call_603442.call(nil, query_603443, nil, formData_603444, nil)

var postDescribeServiceAccessPolicies* = Call_PostDescribeServiceAccessPolicies_603428(
    name: "postDescribeServiceAccessPolicies", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeServiceAccessPolicies",
    validator: validate_PostDescribeServiceAccessPolicies_603429, base: "/",
    url: url_PostDescribeServiceAccessPolicies_603430,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeServiceAccessPolicies_603412 = ref object of OpenApiRestCall_602433
proc url_GetDescribeServiceAccessPolicies_603414(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeServiceAccessPolicies_603413(path: JsonNode;
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
  var valid_603415 = query.getOrDefault("Action")
  valid_603415 = validateParameter(valid_603415, JString, required = true, default = newJString(
      "DescribeServiceAccessPolicies"))
  if valid_603415 != nil:
    section.add "Action", valid_603415
  var valid_603416 = query.getOrDefault("DomainName")
  valid_603416 = validateParameter(valid_603416, JString, required = true,
                                 default = nil)
  if valid_603416 != nil:
    section.add "DomainName", valid_603416
  var valid_603417 = query.getOrDefault("Version")
  valid_603417 = validateParameter(valid_603417, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_603417 != nil:
    section.add "Version", valid_603417
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
  var valid_603418 = header.getOrDefault("X-Amz-Date")
  valid_603418 = validateParameter(valid_603418, JString, required = false,
                                 default = nil)
  if valid_603418 != nil:
    section.add "X-Amz-Date", valid_603418
  var valid_603419 = header.getOrDefault("X-Amz-Security-Token")
  valid_603419 = validateParameter(valid_603419, JString, required = false,
                                 default = nil)
  if valid_603419 != nil:
    section.add "X-Amz-Security-Token", valid_603419
  var valid_603420 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603420 = validateParameter(valid_603420, JString, required = false,
                                 default = nil)
  if valid_603420 != nil:
    section.add "X-Amz-Content-Sha256", valid_603420
  var valid_603421 = header.getOrDefault("X-Amz-Algorithm")
  valid_603421 = validateParameter(valid_603421, JString, required = false,
                                 default = nil)
  if valid_603421 != nil:
    section.add "X-Amz-Algorithm", valid_603421
  var valid_603422 = header.getOrDefault("X-Amz-Signature")
  valid_603422 = validateParameter(valid_603422, JString, required = false,
                                 default = nil)
  if valid_603422 != nil:
    section.add "X-Amz-Signature", valid_603422
  var valid_603423 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603423 = validateParameter(valid_603423, JString, required = false,
                                 default = nil)
  if valid_603423 != nil:
    section.add "X-Amz-SignedHeaders", valid_603423
  var valid_603424 = header.getOrDefault("X-Amz-Credential")
  valid_603424 = validateParameter(valid_603424, JString, required = false,
                                 default = nil)
  if valid_603424 != nil:
    section.add "X-Amz-Credential", valid_603424
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603425: Call_GetDescribeServiceAccessPolicies_603412;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets information about the resource-based policies that control access to the domain's document and search services.
  ## 
  let valid = call_603425.validator(path, query, header, formData, body)
  let scheme = call_603425.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603425.url(scheme.get, call_603425.host, call_603425.base,
                         call_603425.route, valid.getOrDefault("path"))
  result = hook(call_603425, url, valid)

proc call*(call_603426: Call_GetDescribeServiceAccessPolicies_603412;
          DomainName: string; Action: string = "DescribeServiceAccessPolicies";
          Version: string = "2011-02-01"): Recallable =
  ## getDescribeServiceAccessPolicies
  ## Gets information about the resource-based policies that control access to the domain's document and search services.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_603427 = newJObject()
  add(query_603427, "Action", newJString(Action))
  add(query_603427, "DomainName", newJString(DomainName))
  add(query_603427, "Version", newJString(Version))
  result = call_603426.call(nil, query_603427, nil, nil, nil)

var getDescribeServiceAccessPolicies* = Call_GetDescribeServiceAccessPolicies_603412(
    name: "getDescribeServiceAccessPolicies", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeServiceAccessPolicies",
    validator: validate_GetDescribeServiceAccessPolicies_603413, base: "/",
    url: url_GetDescribeServiceAccessPolicies_603414,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeStemmingOptions_603461 = ref object of OpenApiRestCall_602433
proc url_PostDescribeStemmingOptions_603463(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeStemmingOptions_603462(path: JsonNode; query: JsonNode;
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
  var valid_603464 = query.getOrDefault("Action")
  valid_603464 = validateParameter(valid_603464, JString, required = true, default = newJString(
      "DescribeStemmingOptions"))
  if valid_603464 != nil:
    section.add "Action", valid_603464
  var valid_603465 = query.getOrDefault("Version")
  valid_603465 = validateParameter(valid_603465, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_603465 != nil:
    section.add "Version", valid_603465
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
  var valid_603466 = header.getOrDefault("X-Amz-Date")
  valid_603466 = validateParameter(valid_603466, JString, required = false,
                                 default = nil)
  if valid_603466 != nil:
    section.add "X-Amz-Date", valid_603466
  var valid_603467 = header.getOrDefault("X-Amz-Security-Token")
  valid_603467 = validateParameter(valid_603467, JString, required = false,
                                 default = nil)
  if valid_603467 != nil:
    section.add "X-Amz-Security-Token", valid_603467
  var valid_603468 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603468 = validateParameter(valid_603468, JString, required = false,
                                 default = nil)
  if valid_603468 != nil:
    section.add "X-Amz-Content-Sha256", valid_603468
  var valid_603469 = header.getOrDefault("X-Amz-Algorithm")
  valid_603469 = validateParameter(valid_603469, JString, required = false,
                                 default = nil)
  if valid_603469 != nil:
    section.add "X-Amz-Algorithm", valid_603469
  var valid_603470 = header.getOrDefault("X-Amz-Signature")
  valid_603470 = validateParameter(valid_603470, JString, required = false,
                                 default = nil)
  if valid_603470 != nil:
    section.add "X-Amz-Signature", valid_603470
  var valid_603471 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603471 = validateParameter(valid_603471, JString, required = false,
                                 default = nil)
  if valid_603471 != nil:
    section.add "X-Amz-SignedHeaders", valid_603471
  var valid_603472 = header.getOrDefault("X-Amz-Credential")
  valid_603472 = validateParameter(valid_603472, JString, required = false,
                                 default = nil)
  if valid_603472 != nil:
    section.add "X-Amz-Credential", valid_603472
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_603473 = formData.getOrDefault("DomainName")
  valid_603473 = validateParameter(valid_603473, JString, required = true,
                                 default = nil)
  if valid_603473 != nil:
    section.add "DomainName", valid_603473
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603474: Call_PostDescribeStemmingOptions_603461; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the stemming dictionary configured for the search domain.
  ## 
  let valid = call_603474.validator(path, query, header, formData, body)
  let scheme = call_603474.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603474.url(scheme.get, call_603474.host, call_603474.base,
                         call_603474.route, valid.getOrDefault("path"))
  result = hook(call_603474, url, valid)

proc call*(call_603475: Call_PostDescribeStemmingOptions_603461;
          DomainName: string; Action: string = "DescribeStemmingOptions";
          Version: string = "2011-02-01"): Recallable =
  ## postDescribeStemmingOptions
  ## Gets the stemming dictionary configured for the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603476 = newJObject()
  var formData_603477 = newJObject()
  add(formData_603477, "DomainName", newJString(DomainName))
  add(query_603476, "Action", newJString(Action))
  add(query_603476, "Version", newJString(Version))
  result = call_603475.call(nil, query_603476, nil, formData_603477, nil)

var postDescribeStemmingOptions* = Call_PostDescribeStemmingOptions_603461(
    name: "postDescribeStemmingOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeStemmingOptions",
    validator: validate_PostDescribeStemmingOptions_603462, base: "/",
    url: url_PostDescribeStemmingOptions_603463,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeStemmingOptions_603445 = ref object of OpenApiRestCall_602433
proc url_GetDescribeStemmingOptions_603447(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeStemmingOptions_603446(path: JsonNode; query: JsonNode;
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
  var valid_603448 = query.getOrDefault("Action")
  valid_603448 = validateParameter(valid_603448, JString, required = true, default = newJString(
      "DescribeStemmingOptions"))
  if valid_603448 != nil:
    section.add "Action", valid_603448
  var valid_603449 = query.getOrDefault("DomainName")
  valid_603449 = validateParameter(valid_603449, JString, required = true,
                                 default = nil)
  if valid_603449 != nil:
    section.add "DomainName", valid_603449
  var valid_603450 = query.getOrDefault("Version")
  valid_603450 = validateParameter(valid_603450, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_603450 != nil:
    section.add "Version", valid_603450
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
  var valid_603451 = header.getOrDefault("X-Amz-Date")
  valid_603451 = validateParameter(valid_603451, JString, required = false,
                                 default = nil)
  if valid_603451 != nil:
    section.add "X-Amz-Date", valid_603451
  var valid_603452 = header.getOrDefault("X-Amz-Security-Token")
  valid_603452 = validateParameter(valid_603452, JString, required = false,
                                 default = nil)
  if valid_603452 != nil:
    section.add "X-Amz-Security-Token", valid_603452
  var valid_603453 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603453 = validateParameter(valid_603453, JString, required = false,
                                 default = nil)
  if valid_603453 != nil:
    section.add "X-Amz-Content-Sha256", valid_603453
  var valid_603454 = header.getOrDefault("X-Amz-Algorithm")
  valid_603454 = validateParameter(valid_603454, JString, required = false,
                                 default = nil)
  if valid_603454 != nil:
    section.add "X-Amz-Algorithm", valid_603454
  var valid_603455 = header.getOrDefault("X-Amz-Signature")
  valid_603455 = validateParameter(valid_603455, JString, required = false,
                                 default = nil)
  if valid_603455 != nil:
    section.add "X-Amz-Signature", valid_603455
  var valid_603456 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603456 = validateParameter(valid_603456, JString, required = false,
                                 default = nil)
  if valid_603456 != nil:
    section.add "X-Amz-SignedHeaders", valid_603456
  var valid_603457 = header.getOrDefault("X-Amz-Credential")
  valid_603457 = validateParameter(valid_603457, JString, required = false,
                                 default = nil)
  if valid_603457 != nil:
    section.add "X-Amz-Credential", valid_603457
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603458: Call_GetDescribeStemmingOptions_603445; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the stemming dictionary configured for the search domain.
  ## 
  let valid = call_603458.validator(path, query, header, formData, body)
  let scheme = call_603458.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603458.url(scheme.get, call_603458.host, call_603458.base,
                         call_603458.route, valid.getOrDefault("path"))
  result = hook(call_603458, url, valid)

proc call*(call_603459: Call_GetDescribeStemmingOptions_603445; DomainName: string;
          Action: string = "DescribeStemmingOptions"; Version: string = "2011-02-01"): Recallable =
  ## getDescribeStemmingOptions
  ## Gets the stemming dictionary configured for the search domain.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_603460 = newJObject()
  add(query_603460, "Action", newJString(Action))
  add(query_603460, "DomainName", newJString(DomainName))
  add(query_603460, "Version", newJString(Version))
  result = call_603459.call(nil, query_603460, nil, nil, nil)

var getDescribeStemmingOptions* = Call_GetDescribeStemmingOptions_603445(
    name: "getDescribeStemmingOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeStemmingOptions",
    validator: validate_GetDescribeStemmingOptions_603446, base: "/",
    url: url_GetDescribeStemmingOptions_603447,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeStopwordOptions_603494 = ref object of OpenApiRestCall_602433
proc url_PostDescribeStopwordOptions_603496(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeStopwordOptions_603495(path: JsonNode; query: JsonNode;
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
  var valid_603497 = query.getOrDefault("Action")
  valid_603497 = validateParameter(valid_603497, JString, required = true, default = newJString(
      "DescribeStopwordOptions"))
  if valid_603497 != nil:
    section.add "Action", valid_603497
  var valid_603498 = query.getOrDefault("Version")
  valid_603498 = validateParameter(valid_603498, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_603498 != nil:
    section.add "Version", valid_603498
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
  var valid_603499 = header.getOrDefault("X-Amz-Date")
  valid_603499 = validateParameter(valid_603499, JString, required = false,
                                 default = nil)
  if valid_603499 != nil:
    section.add "X-Amz-Date", valid_603499
  var valid_603500 = header.getOrDefault("X-Amz-Security-Token")
  valid_603500 = validateParameter(valid_603500, JString, required = false,
                                 default = nil)
  if valid_603500 != nil:
    section.add "X-Amz-Security-Token", valid_603500
  var valid_603501 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603501 = validateParameter(valid_603501, JString, required = false,
                                 default = nil)
  if valid_603501 != nil:
    section.add "X-Amz-Content-Sha256", valid_603501
  var valid_603502 = header.getOrDefault("X-Amz-Algorithm")
  valid_603502 = validateParameter(valid_603502, JString, required = false,
                                 default = nil)
  if valid_603502 != nil:
    section.add "X-Amz-Algorithm", valid_603502
  var valid_603503 = header.getOrDefault("X-Amz-Signature")
  valid_603503 = validateParameter(valid_603503, JString, required = false,
                                 default = nil)
  if valid_603503 != nil:
    section.add "X-Amz-Signature", valid_603503
  var valid_603504 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603504 = validateParameter(valid_603504, JString, required = false,
                                 default = nil)
  if valid_603504 != nil:
    section.add "X-Amz-SignedHeaders", valid_603504
  var valid_603505 = header.getOrDefault("X-Amz-Credential")
  valid_603505 = validateParameter(valid_603505, JString, required = false,
                                 default = nil)
  if valid_603505 != nil:
    section.add "X-Amz-Credential", valid_603505
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_603506 = formData.getOrDefault("DomainName")
  valid_603506 = validateParameter(valid_603506, JString, required = true,
                                 default = nil)
  if valid_603506 != nil:
    section.add "DomainName", valid_603506
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603507: Call_PostDescribeStopwordOptions_603494; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the stopwords configured for the search domain.
  ## 
  let valid = call_603507.validator(path, query, header, formData, body)
  let scheme = call_603507.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603507.url(scheme.get, call_603507.host, call_603507.base,
                         call_603507.route, valid.getOrDefault("path"))
  result = hook(call_603507, url, valid)

proc call*(call_603508: Call_PostDescribeStopwordOptions_603494;
          DomainName: string; Action: string = "DescribeStopwordOptions";
          Version: string = "2011-02-01"): Recallable =
  ## postDescribeStopwordOptions
  ## Gets the stopwords configured for the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603509 = newJObject()
  var formData_603510 = newJObject()
  add(formData_603510, "DomainName", newJString(DomainName))
  add(query_603509, "Action", newJString(Action))
  add(query_603509, "Version", newJString(Version))
  result = call_603508.call(nil, query_603509, nil, formData_603510, nil)

var postDescribeStopwordOptions* = Call_PostDescribeStopwordOptions_603494(
    name: "postDescribeStopwordOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeStopwordOptions",
    validator: validate_PostDescribeStopwordOptions_603495, base: "/",
    url: url_PostDescribeStopwordOptions_603496,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeStopwordOptions_603478 = ref object of OpenApiRestCall_602433
proc url_GetDescribeStopwordOptions_603480(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeStopwordOptions_603479(path: JsonNode; query: JsonNode;
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
  var valid_603481 = query.getOrDefault("Action")
  valid_603481 = validateParameter(valid_603481, JString, required = true, default = newJString(
      "DescribeStopwordOptions"))
  if valid_603481 != nil:
    section.add "Action", valid_603481
  var valid_603482 = query.getOrDefault("DomainName")
  valid_603482 = validateParameter(valid_603482, JString, required = true,
                                 default = nil)
  if valid_603482 != nil:
    section.add "DomainName", valid_603482
  var valid_603483 = query.getOrDefault("Version")
  valid_603483 = validateParameter(valid_603483, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_603483 != nil:
    section.add "Version", valid_603483
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
  var valid_603484 = header.getOrDefault("X-Amz-Date")
  valid_603484 = validateParameter(valid_603484, JString, required = false,
                                 default = nil)
  if valid_603484 != nil:
    section.add "X-Amz-Date", valid_603484
  var valid_603485 = header.getOrDefault("X-Amz-Security-Token")
  valid_603485 = validateParameter(valid_603485, JString, required = false,
                                 default = nil)
  if valid_603485 != nil:
    section.add "X-Amz-Security-Token", valid_603485
  var valid_603486 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603486 = validateParameter(valid_603486, JString, required = false,
                                 default = nil)
  if valid_603486 != nil:
    section.add "X-Amz-Content-Sha256", valid_603486
  var valid_603487 = header.getOrDefault("X-Amz-Algorithm")
  valid_603487 = validateParameter(valid_603487, JString, required = false,
                                 default = nil)
  if valid_603487 != nil:
    section.add "X-Amz-Algorithm", valid_603487
  var valid_603488 = header.getOrDefault("X-Amz-Signature")
  valid_603488 = validateParameter(valid_603488, JString, required = false,
                                 default = nil)
  if valid_603488 != nil:
    section.add "X-Amz-Signature", valid_603488
  var valid_603489 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603489 = validateParameter(valid_603489, JString, required = false,
                                 default = nil)
  if valid_603489 != nil:
    section.add "X-Amz-SignedHeaders", valid_603489
  var valid_603490 = header.getOrDefault("X-Amz-Credential")
  valid_603490 = validateParameter(valid_603490, JString, required = false,
                                 default = nil)
  if valid_603490 != nil:
    section.add "X-Amz-Credential", valid_603490
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603491: Call_GetDescribeStopwordOptions_603478; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the stopwords configured for the search domain.
  ## 
  let valid = call_603491.validator(path, query, header, formData, body)
  let scheme = call_603491.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603491.url(scheme.get, call_603491.host, call_603491.base,
                         call_603491.route, valid.getOrDefault("path"))
  result = hook(call_603491, url, valid)

proc call*(call_603492: Call_GetDescribeStopwordOptions_603478; DomainName: string;
          Action: string = "DescribeStopwordOptions"; Version: string = "2011-02-01"): Recallable =
  ## getDescribeStopwordOptions
  ## Gets the stopwords configured for the search domain.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_603493 = newJObject()
  add(query_603493, "Action", newJString(Action))
  add(query_603493, "DomainName", newJString(DomainName))
  add(query_603493, "Version", newJString(Version))
  result = call_603492.call(nil, query_603493, nil, nil, nil)

var getDescribeStopwordOptions* = Call_GetDescribeStopwordOptions_603478(
    name: "getDescribeStopwordOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeStopwordOptions",
    validator: validate_GetDescribeStopwordOptions_603479, base: "/",
    url: url_GetDescribeStopwordOptions_603480,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeSynonymOptions_603527 = ref object of OpenApiRestCall_602433
proc url_PostDescribeSynonymOptions_603529(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeSynonymOptions_603528(path: JsonNode; query: JsonNode;
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
  var valid_603530 = query.getOrDefault("Action")
  valid_603530 = validateParameter(valid_603530, JString, required = true,
                                 default = newJString("DescribeSynonymOptions"))
  if valid_603530 != nil:
    section.add "Action", valid_603530
  var valid_603531 = query.getOrDefault("Version")
  valid_603531 = validateParameter(valid_603531, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_603531 != nil:
    section.add "Version", valid_603531
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
  var valid_603532 = header.getOrDefault("X-Amz-Date")
  valid_603532 = validateParameter(valid_603532, JString, required = false,
                                 default = nil)
  if valid_603532 != nil:
    section.add "X-Amz-Date", valid_603532
  var valid_603533 = header.getOrDefault("X-Amz-Security-Token")
  valid_603533 = validateParameter(valid_603533, JString, required = false,
                                 default = nil)
  if valid_603533 != nil:
    section.add "X-Amz-Security-Token", valid_603533
  var valid_603534 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603534 = validateParameter(valid_603534, JString, required = false,
                                 default = nil)
  if valid_603534 != nil:
    section.add "X-Amz-Content-Sha256", valid_603534
  var valid_603535 = header.getOrDefault("X-Amz-Algorithm")
  valid_603535 = validateParameter(valid_603535, JString, required = false,
                                 default = nil)
  if valid_603535 != nil:
    section.add "X-Amz-Algorithm", valid_603535
  var valid_603536 = header.getOrDefault("X-Amz-Signature")
  valid_603536 = validateParameter(valid_603536, JString, required = false,
                                 default = nil)
  if valid_603536 != nil:
    section.add "X-Amz-Signature", valid_603536
  var valid_603537 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603537 = validateParameter(valid_603537, JString, required = false,
                                 default = nil)
  if valid_603537 != nil:
    section.add "X-Amz-SignedHeaders", valid_603537
  var valid_603538 = header.getOrDefault("X-Amz-Credential")
  valid_603538 = validateParameter(valid_603538, JString, required = false,
                                 default = nil)
  if valid_603538 != nil:
    section.add "X-Amz-Credential", valid_603538
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_603539 = formData.getOrDefault("DomainName")
  valid_603539 = validateParameter(valid_603539, JString, required = true,
                                 default = nil)
  if valid_603539 != nil:
    section.add "DomainName", valid_603539
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603540: Call_PostDescribeSynonymOptions_603527; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the synonym dictionary configured for the search domain.
  ## 
  let valid = call_603540.validator(path, query, header, formData, body)
  let scheme = call_603540.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603540.url(scheme.get, call_603540.host, call_603540.base,
                         call_603540.route, valid.getOrDefault("path"))
  result = hook(call_603540, url, valid)

proc call*(call_603541: Call_PostDescribeSynonymOptions_603527; DomainName: string;
          Action: string = "DescribeSynonymOptions"; Version: string = "2011-02-01"): Recallable =
  ## postDescribeSynonymOptions
  ## Gets the synonym dictionary configured for the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603542 = newJObject()
  var formData_603543 = newJObject()
  add(formData_603543, "DomainName", newJString(DomainName))
  add(query_603542, "Action", newJString(Action))
  add(query_603542, "Version", newJString(Version))
  result = call_603541.call(nil, query_603542, nil, formData_603543, nil)

var postDescribeSynonymOptions* = Call_PostDescribeSynonymOptions_603527(
    name: "postDescribeSynonymOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeSynonymOptions",
    validator: validate_PostDescribeSynonymOptions_603528, base: "/",
    url: url_PostDescribeSynonymOptions_603529,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeSynonymOptions_603511 = ref object of OpenApiRestCall_602433
proc url_GetDescribeSynonymOptions_603513(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeSynonymOptions_603512(path: JsonNode; query: JsonNode;
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
  var valid_603514 = query.getOrDefault("Action")
  valid_603514 = validateParameter(valid_603514, JString, required = true,
                                 default = newJString("DescribeSynonymOptions"))
  if valid_603514 != nil:
    section.add "Action", valid_603514
  var valid_603515 = query.getOrDefault("DomainName")
  valid_603515 = validateParameter(valid_603515, JString, required = true,
                                 default = nil)
  if valid_603515 != nil:
    section.add "DomainName", valid_603515
  var valid_603516 = query.getOrDefault("Version")
  valid_603516 = validateParameter(valid_603516, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_603516 != nil:
    section.add "Version", valid_603516
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
  var valid_603517 = header.getOrDefault("X-Amz-Date")
  valid_603517 = validateParameter(valid_603517, JString, required = false,
                                 default = nil)
  if valid_603517 != nil:
    section.add "X-Amz-Date", valid_603517
  var valid_603518 = header.getOrDefault("X-Amz-Security-Token")
  valid_603518 = validateParameter(valid_603518, JString, required = false,
                                 default = nil)
  if valid_603518 != nil:
    section.add "X-Amz-Security-Token", valid_603518
  var valid_603519 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603519 = validateParameter(valid_603519, JString, required = false,
                                 default = nil)
  if valid_603519 != nil:
    section.add "X-Amz-Content-Sha256", valid_603519
  var valid_603520 = header.getOrDefault("X-Amz-Algorithm")
  valid_603520 = validateParameter(valid_603520, JString, required = false,
                                 default = nil)
  if valid_603520 != nil:
    section.add "X-Amz-Algorithm", valid_603520
  var valid_603521 = header.getOrDefault("X-Amz-Signature")
  valid_603521 = validateParameter(valid_603521, JString, required = false,
                                 default = nil)
  if valid_603521 != nil:
    section.add "X-Amz-Signature", valid_603521
  var valid_603522 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603522 = validateParameter(valid_603522, JString, required = false,
                                 default = nil)
  if valid_603522 != nil:
    section.add "X-Amz-SignedHeaders", valid_603522
  var valid_603523 = header.getOrDefault("X-Amz-Credential")
  valid_603523 = validateParameter(valid_603523, JString, required = false,
                                 default = nil)
  if valid_603523 != nil:
    section.add "X-Amz-Credential", valid_603523
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603524: Call_GetDescribeSynonymOptions_603511; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the synonym dictionary configured for the search domain.
  ## 
  let valid = call_603524.validator(path, query, header, formData, body)
  let scheme = call_603524.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603524.url(scheme.get, call_603524.host, call_603524.base,
                         call_603524.route, valid.getOrDefault("path"))
  result = hook(call_603524, url, valid)

proc call*(call_603525: Call_GetDescribeSynonymOptions_603511; DomainName: string;
          Action: string = "DescribeSynonymOptions"; Version: string = "2011-02-01"): Recallable =
  ## getDescribeSynonymOptions
  ## Gets the synonym dictionary configured for the search domain.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_603526 = newJObject()
  add(query_603526, "Action", newJString(Action))
  add(query_603526, "DomainName", newJString(DomainName))
  add(query_603526, "Version", newJString(Version))
  result = call_603525.call(nil, query_603526, nil, nil, nil)

var getDescribeSynonymOptions* = Call_GetDescribeSynonymOptions_603511(
    name: "getDescribeSynonymOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeSynonymOptions",
    validator: validate_GetDescribeSynonymOptions_603512, base: "/",
    url: url_GetDescribeSynonymOptions_603513,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostIndexDocuments_603560 = ref object of OpenApiRestCall_602433
proc url_PostIndexDocuments_603562(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostIndexDocuments_603561(path: JsonNode; query: JsonNode;
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
  var valid_603563 = query.getOrDefault("Action")
  valid_603563 = validateParameter(valid_603563, JString, required = true,
                                 default = newJString("IndexDocuments"))
  if valid_603563 != nil:
    section.add "Action", valid_603563
  var valid_603564 = query.getOrDefault("Version")
  valid_603564 = validateParameter(valid_603564, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_603564 != nil:
    section.add "Version", valid_603564
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
  var valid_603565 = header.getOrDefault("X-Amz-Date")
  valid_603565 = validateParameter(valid_603565, JString, required = false,
                                 default = nil)
  if valid_603565 != nil:
    section.add "X-Amz-Date", valid_603565
  var valid_603566 = header.getOrDefault("X-Amz-Security-Token")
  valid_603566 = validateParameter(valid_603566, JString, required = false,
                                 default = nil)
  if valid_603566 != nil:
    section.add "X-Amz-Security-Token", valid_603566
  var valid_603567 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603567 = validateParameter(valid_603567, JString, required = false,
                                 default = nil)
  if valid_603567 != nil:
    section.add "X-Amz-Content-Sha256", valid_603567
  var valid_603568 = header.getOrDefault("X-Amz-Algorithm")
  valid_603568 = validateParameter(valid_603568, JString, required = false,
                                 default = nil)
  if valid_603568 != nil:
    section.add "X-Amz-Algorithm", valid_603568
  var valid_603569 = header.getOrDefault("X-Amz-Signature")
  valid_603569 = validateParameter(valid_603569, JString, required = false,
                                 default = nil)
  if valid_603569 != nil:
    section.add "X-Amz-Signature", valid_603569
  var valid_603570 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603570 = validateParameter(valid_603570, JString, required = false,
                                 default = nil)
  if valid_603570 != nil:
    section.add "X-Amz-SignedHeaders", valid_603570
  var valid_603571 = header.getOrDefault("X-Amz-Credential")
  valid_603571 = validateParameter(valid_603571, JString, required = false,
                                 default = nil)
  if valid_603571 != nil:
    section.add "X-Amz-Credential", valid_603571
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_603572 = formData.getOrDefault("DomainName")
  valid_603572 = validateParameter(valid_603572, JString, required = true,
                                 default = nil)
  if valid_603572 != nil:
    section.add "DomainName", valid_603572
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603573: Call_PostIndexDocuments_603560; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Tells the search domain to start indexing its documents using the latest text processing options and <code>IndexFields</code>. This operation must be invoked to make options whose <a>OptionStatus</a> has <code>OptionState</code> of <code>RequiresIndexDocuments</code> visible in search results.
  ## 
  let valid = call_603573.validator(path, query, header, formData, body)
  let scheme = call_603573.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603573.url(scheme.get, call_603573.host, call_603573.base,
                         call_603573.route, valid.getOrDefault("path"))
  result = hook(call_603573, url, valid)

proc call*(call_603574: Call_PostIndexDocuments_603560; DomainName: string;
          Action: string = "IndexDocuments"; Version: string = "2011-02-01"): Recallable =
  ## postIndexDocuments
  ## Tells the search domain to start indexing its documents using the latest text processing options and <code>IndexFields</code>. This operation must be invoked to make options whose <a>OptionStatus</a> has <code>OptionState</code> of <code>RequiresIndexDocuments</code> visible in search results.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_603575 = newJObject()
  var formData_603576 = newJObject()
  add(formData_603576, "DomainName", newJString(DomainName))
  add(query_603575, "Action", newJString(Action))
  add(query_603575, "Version", newJString(Version))
  result = call_603574.call(nil, query_603575, nil, formData_603576, nil)

var postIndexDocuments* = Call_PostIndexDocuments_603560(
    name: "postIndexDocuments", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=IndexDocuments",
    validator: validate_PostIndexDocuments_603561, base: "/",
    url: url_PostIndexDocuments_603562, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIndexDocuments_603544 = ref object of OpenApiRestCall_602433
proc url_GetIndexDocuments_603546(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetIndexDocuments_603545(path: JsonNode; query: JsonNode;
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
  var valid_603547 = query.getOrDefault("Action")
  valid_603547 = validateParameter(valid_603547, JString, required = true,
                                 default = newJString("IndexDocuments"))
  if valid_603547 != nil:
    section.add "Action", valid_603547
  var valid_603548 = query.getOrDefault("DomainName")
  valid_603548 = validateParameter(valid_603548, JString, required = true,
                                 default = nil)
  if valid_603548 != nil:
    section.add "DomainName", valid_603548
  var valid_603549 = query.getOrDefault("Version")
  valid_603549 = validateParameter(valid_603549, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_603549 != nil:
    section.add "Version", valid_603549
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
  var valid_603550 = header.getOrDefault("X-Amz-Date")
  valid_603550 = validateParameter(valid_603550, JString, required = false,
                                 default = nil)
  if valid_603550 != nil:
    section.add "X-Amz-Date", valid_603550
  var valid_603551 = header.getOrDefault("X-Amz-Security-Token")
  valid_603551 = validateParameter(valid_603551, JString, required = false,
                                 default = nil)
  if valid_603551 != nil:
    section.add "X-Amz-Security-Token", valid_603551
  var valid_603552 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603552 = validateParameter(valid_603552, JString, required = false,
                                 default = nil)
  if valid_603552 != nil:
    section.add "X-Amz-Content-Sha256", valid_603552
  var valid_603553 = header.getOrDefault("X-Amz-Algorithm")
  valid_603553 = validateParameter(valid_603553, JString, required = false,
                                 default = nil)
  if valid_603553 != nil:
    section.add "X-Amz-Algorithm", valid_603553
  var valid_603554 = header.getOrDefault("X-Amz-Signature")
  valid_603554 = validateParameter(valid_603554, JString, required = false,
                                 default = nil)
  if valid_603554 != nil:
    section.add "X-Amz-Signature", valid_603554
  var valid_603555 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603555 = validateParameter(valid_603555, JString, required = false,
                                 default = nil)
  if valid_603555 != nil:
    section.add "X-Amz-SignedHeaders", valid_603555
  var valid_603556 = header.getOrDefault("X-Amz-Credential")
  valid_603556 = validateParameter(valid_603556, JString, required = false,
                                 default = nil)
  if valid_603556 != nil:
    section.add "X-Amz-Credential", valid_603556
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603557: Call_GetIndexDocuments_603544; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Tells the search domain to start indexing its documents using the latest text processing options and <code>IndexFields</code>. This operation must be invoked to make options whose <a>OptionStatus</a> has <code>OptionState</code> of <code>RequiresIndexDocuments</code> visible in search results.
  ## 
  let valid = call_603557.validator(path, query, header, formData, body)
  let scheme = call_603557.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603557.url(scheme.get, call_603557.host, call_603557.base,
                         call_603557.route, valid.getOrDefault("path"))
  result = hook(call_603557, url, valid)

proc call*(call_603558: Call_GetIndexDocuments_603544; DomainName: string;
          Action: string = "IndexDocuments"; Version: string = "2011-02-01"): Recallable =
  ## getIndexDocuments
  ## Tells the search domain to start indexing its documents using the latest text processing options and <code>IndexFields</code>. This operation must be invoked to make options whose <a>OptionStatus</a> has <code>OptionState</code> of <code>RequiresIndexDocuments</code> visible in search results.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_603559 = newJObject()
  add(query_603559, "Action", newJString(Action))
  add(query_603559, "DomainName", newJString(DomainName))
  add(query_603559, "Version", newJString(Version))
  result = call_603558.call(nil, query_603559, nil, nil, nil)

var getIndexDocuments* = Call_GetIndexDocuments_603544(name: "getIndexDocuments",
    meth: HttpMethod.HttpGet, host: "cloudsearch.amazonaws.com",
    route: "/#Action=IndexDocuments", validator: validate_GetIndexDocuments_603545,
    base: "/", url: url_GetIndexDocuments_603546,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateAvailabilityOptions_603594 = ref object of OpenApiRestCall_602433
proc url_PostUpdateAvailabilityOptions_603596(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostUpdateAvailabilityOptions_603595(path: JsonNode; query: JsonNode;
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
  var valid_603597 = query.getOrDefault("Action")
  valid_603597 = validateParameter(valid_603597, JString, required = true, default = newJString(
      "UpdateAvailabilityOptions"))
  if valid_603597 != nil:
    section.add "Action", valid_603597
  var valid_603598 = query.getOrDefault("Version")
  valid_603598 = validateParameter(valid_603598, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_603598 != nil:
    section.add "Version", valid_603598
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
  var valid_603599 = header.getOrDefault("X-Amz-Date")
  valid_603599 = validateParameter(valid_603599, JString, required = false,
                                 default = nil)
  if valid_603599 != nil:
    section.add "X-Amz-Date", valid_603599
  var valid_603600 = header.getOrDefault("X-Amz-Security-Token")
  valid_603600 = validateParameter(valid_603600, JString, required = false,
                                 default = nil)
  if valid_603600 != nil:
    section.add "X-Amz-Security-Token", valid_603600
  var valid_603601 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603601 = validateParameter(valid_603601, JString, required = false,
                                 default = nil)
  if valid_603601 != nil:
    section.add "X-Amz-Content-Sha256", valid_603601
  var valid_603602 = header.getOrDefault("X-Amz-Algorithm")
  valid_603602 = validateParameter(valid_603602, JString, required = false,
                                 default = nil)
  if valid_603602 != nil:
    section.add "X-Amz-Algorithm", valid_603602
  var valid_603603 = header.getOrDefault("X-Amz-Signature")
  valid_603603 = validateParameter(valid_603603, JString, required = false,
                                 default = nil)
  if valid_603603 != nil:
    section.add "X-Amz-Signature", valid_603603
  var valid_603604 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603604 = validateParameter(valid_603604, JString, required = false,
                                 default = nil)
  if valid_603604 != nil:
    section.add "X-Amz-SignedHeaders", valid_603604
  var valid_603605 = header.getOrDefault("X-Amz-Credential")
  valid_603605 = validateParameter(valid_603605, JString, required = false,
                                 default = nil)
  if valid_603605 != nil:
    section.add "X-Amz-Credential", valid_603605
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   MultiAZ: JBool (required)
  ##          : You expand an existing search domain to a second Availability Zone by setting the Multi-AZ option to true. Similarly, you can turn off the Multi-AZ option to downgrade the domain to a single Availability Zone by setting the Multi-AZ option to <code>false</code>. 
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_603606 = formData.getOrDefault("DomainName")
  valid_603606 = validateParameter(valid_603606, JString, required = true,
                                 default = nil)
  if valid_603606 != nil:
    section.add "DomainName", valid_603606
  var valid_603607 = formData.getOrDefault("MultiAZ")
  valid_603607 = validateParameter(valid_603607, JBool, required = true, default = nil)
  if valid_603607 != nil:
    section.add "MultiAZ", valid_603607
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603608: Call_PostUpdateAvailabilityOptions_603594; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_603608.validator(path, query, header, formData, body)
  let scheme = call_603608.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603608.url(scheme.get, call_603608.host, call_603608.base,
                         call_603608.route, valid.getOrDefault("path"))
  result = hook(call_603608, url, valid)

proc call*(call_603609: Call_PostUpdateAvailabilityOptions_603594;
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
  var query_603610 = newJObject()
  var formData_603611 = newJObject()
  add(formData_603611, "DomainName", newJString(DomainName))
  add(formData_603611, "MultiAZ", newJBool(MultiAZ))
  add(query_603610, "Action", newJString(Action))
  add(query_603610, "Version", newJString(Version))
  result = call_603609.call(nil, query_603610, nil, formData_603611, nil)

var postUpdateAvailabilityOptions* = Call_PostUpdateAvailabilityOptions_603594(
    name: "postUpdateAvailabilityOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateAvailabilityOptions",
    validator: validate_PostUpdateAvailabilityOptions_603595, base: "/",
    url: url_PostUpdateAvailabilityOptions_603596,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateAvailabilityOptions_603577 = ref object of OpenApiRestCall_602433
proc url_GetUpdateAvailabilityOptions_603579(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetUpdateAvailabilityOptions_603578(path: JsonNode; query: JsonNode;
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
  var valid_603580 = query.getOrDefault("MultiAZ")
  valid_603580 = validateParameter(valid_603580, JBool, required = true, default = nil)
  if valid_603580 != nil:
    section.add "MultiAZ", valid_603580
  var valid_603581 = query.getOrDefault("Action")
  valid_603581 = validateParameter(valid_603581, JString, required = true, default = newJString(
      "UpdateAvailabilityOptions"))
  if valid_603581 != nil:
    section.add "Action", valid_603581
  var valid_603582 = query.getOrDefault("DomainName")
  valid_603582 = validateParameter(valid_603582, JString, required = true,
                                 default = nil)
  if valid_603582 != nil:
    section.add "DomainName", valid_603582
  var valid_603583 = query.getOrDefault("Version")
  valid_603583 = validateParameter(valid_603583, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_603583 != nil:
    section.add "Version", valid_603583
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
  var valid_603584 = header.getOrDefault("X-Amz-Date")
  valid_603584 = validateParameter(valid_603584, JString, required = false,
                                 default = nil)
  if valid_603584 != nil:
    section.add "X-Amz-Date", valid_603584
  var valid_603585 = header.getOrDefault("X-Amz-Security-Token")
  valid_603585 = validateParameter(valid_603585, JString, required = false,
                                 default = nil)
  if valid_603585 != nil:
    section.add "X-Amz-Security-Token", valid_603585
  var valid_603586 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603586 = validateParameter(valid_603586, JString, required = false,
                                 default = nil)
  if valid_603586 != nil:
    section.add "X-Amz-Content-Sha256", valid_603586
  var valid_603587 = header.getOrDefault("X-Amz-Algorithm")
  valid_603587 = validateParameter(valid_603587, JString, required = false,
                                 default = nil)
  if valid_603587 != nil:
    section.add "X-Amz-Algorithm", valid_603587
  var valid_603588 = header.getOrDefault("X-Amz-Signature")
  valid_603588 = validateParameter(valid_603588, JString, required = false,
                                 default = nil)
  if valid_603588 != nil:
    section.add "X-Amz-Signature", valid_603588
  var valid_603589 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603589 = validateParameter(valid_603589, JString, required = false,
                                 default = nil)
  if valid_603589 != nil:
    section.add "X-Amz-SignedHeaders", valid_603589
  var valid_603590 = header.getOrDefault("X-Amz-Credential")
  valid_603590 = validateParameter(valid_603590, JString, required = false,
                                 default = nil)
  if valid_603590 != nil:
    section.add "X-Amz-Credential", valid_603590
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603591: Call_GetUpdateAvailabilityOptions_603577; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_603591.validator(path, query, header, formData, body)
  let scheme = call_603591.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603591.url(scheme.get, call_603591.host, call_603591.base,
                         call_603591.route, valid.getOrDefault("path"))
  result = hook(call_603591, url, valid)

proc call*(call_603592: Call_GetUpdateAvailabilityOptions_603577; MultiAZ: bool;
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
  var query_603593 = newJObject()
  add(query_603593, "MultiAZ", newJBool(MultiAZ))
  add(query_603593, "Action", newJString(Action))
  add(query_603593, "DomainName", newJString(DomainName))
  add(query_603593, "Version", newJString(Version))
  result = call_603592.call(nil, query_603593, nil, nil, nil)

var getUpdateAvailabilityOptions* = Call_GetUpdateAvailabilityOptions_603577(
    name: "getUpdateAvailabilityOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateAvailabilityOptions",
    validator: validate_GetUpdateAvailabilityOptions_603578, base: "/",
    url: url_GetUpdateAvailabilityOptions_603579,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateDefaultSearchField_603629 = ref object of OpenApiRestCall_602433
proc url_PostUpdateDefaultSearchField_603631(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostUpdateDefaultSearchField_603630(path: JsonNode; query: JsonNode;
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
  var valid_603632 = query.getOrDefault("Action")
  valid_603632 = validateParameter(valid_603632, JString, required = true, default = newJString(
      "UpdateDefaultSearchField"))
  if valid_603632 != nil:
    section.add "Action", valid_603632
  var valid_603633 = query.getOrDefault("Version")
  valid_603633 = validateParameter(valid_603633, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_603633 != nil:
    section.add "Version", valid_603633
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
  var valid_603634 = header.getOrDefault("X-Amz-Date")
  valid_603634 = validateParameter(valid_603634, JString, required = false,
                                 default = nil)
  if valid_603634 != nil:
    section.add "X-Amz-Date", valid_603634
  var valid_603635 = header.getOrDefault("X-Amz-Security-Token")
  valid_603635 = validateParameter(valid_603635, JString, required = false,
                                 default = nil)
  if valid_603635 != nil:
    section.add "X-Amz-Security-Token", valid_603635
  var valid_603636 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603636 = validateParameter(valid_603636, JString, required = false,
                                 default = nil)
  if valid_603636 != nil:
    section.add "X-Amz-Content-Sha256", valid_603636
  var valid_603637 = header.getOrDefault("X-Amz-Algorithm")
  valid_603637 = validateParameter(valid_603637, JString, required = false,
                                 default = nil)
  if valid_603637 != nil:
    section.add "X-Amz-Algorithm", valid_603637
  var valid_603638 = header.getOrDefault("X-Amz-Signature")
  valid_603638 = validateParameter(valid_603638, JString, required = false,
                                 default = nil)
  if valid_603638 != nil:
    section.add "X-Amz-Signature", valid_603638
  var valid_603639 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603639 = validateParameter(valid_603639, JString, required = false,
                                 default = nil)
  if valid_603639 != nil:
    section.add "X-Amz-SignedHeaders", valid_603639
  var valid_603640 = header.getOrDefault("X-Amz-Credential")
  valid_603640 = validateParameter(valid_603640, JString, required = false,
                                 default = nil)
  if valid_603640 != nil:
    section.add "X-Amz-Credential", valid_603640
  result.add "header", section
  ## parameters in `formData` object:
  ##   DefaultSearchField: JString (required)
  ##                     : The text field to search if the search request does not specify which field to search. The default search field is used when search terms are specified with the <code>q</code> parameter, or if a match expression specified with the <code>bq</code> parameter does not constrain the search to a particular field. The default is an empty string, which automatically searches all text fields.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DefaultSearchField` field"
  var valid_603641 = formData.getOrDefault("DefaultSearchField")
  valid_603641 = validateParameter(valid_603641, JString, required = true,
                                 default = nil)
  if valid_603641 != nil:
    section.add "DefaultSearchField", valid_603641
  var valid_603642 = formData.getOrDefault("DomainName")
  valid_603642 = validateParameter(valid_603642, JString, required = true,
                                 default = nil)
  if valid_603642 != nil:
    section.add "DomainName", valid_603642
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603643: Call_PostUpdateDefaultSearchField_603629; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the default search field for the search domain. The default search field is the text field that is searched when a search request does not specify which fields to search. By default, it is configured to include the contents of all of the domain's text fields. 
  ## 
  let valid = call_603643.validator(path, query, header, formData, body)
  let scheme = call_603643.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603643.url(scheme.get, call_603643.host, call_603643.base,
                         call_603643.route, valid.getOrDefault("path"))
  result = hook(call_603643, url, valid)

proc call*(call_603644: Call_PostUpdateDefaultSearchField_603629;
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
  var query_603645 = newJObject()
  var formData_603646 = newJObject()
  add(formData_603646, "DefaultSearchField", newJString(DefaultSearchField))
  add(formData_603646, "DomainName", newJString(DomainName))
  add(query_603645, "Action", newJString(Action))
  add(query_603645, "Version", newJString(Version))
  result = call_603644.call(nil, query_603645, nil, formData_603646, nil)

var postUpdateDefaultSearchField* = Call_PostUpdateDefaultSearchField_603629(
    name: "postUpdateDefaultSearchField", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateDefaultSearchField",
    validator: validate_PostUpdateDefaultSearchField_603630, base: "/",
    url: url_PostUpdateDefaultSearchField_603631,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateDefaultSearchField_603612 = ref object of OpenApiRestCall_602433
proc url_GetUpdateDefaultSearchField_603614(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetUpdateDefaultSearchField_603613(path: JsonNode; query: JsonNode;
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
  var valid_603615 = query.getOrDefault("Action")
  valid_603615 = validateParameter(valid_603615, JString, required = true, default = newJString(
      "UpdateDefaultSearchField"))
  if valid_603615 != nil:
    section.add "Action", valid_603615
  var valid_603616 = query.getOrDefault("DomainName")
  valid_603616 = validateParameter(valid_603616, JString, required = true,
                                 default = nil)
  if valid_603616 != nil:
    section.add "DomainName", valid_603616
  var valid_603617 = query.getOrDefault("DefaultSearchField")
  valid_603617 = validateParameter(valid_603617, JString, required = true,
                                 default = nil)
  if valid_603617 != nil:
    section.add "DefaultSearchField", valid_603617
  var valid_603618 = query.getOrDefault("Version")
  valid_603618 = validateParameter(valid_603618, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_603618 != nil:
    section.add "Version", valid_603618
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
  var valid_603619 = header.getOrDefault("X-Amz-Date")
  valid_603619 = validateParameter(valid_603619, JString, required = false,
                                 default = nil)
  if valid_603619 != nil:
    section.add "X-Amz-Date", valid_603619
  var valid_603620 = header.getOrDefault("X-Amz-Security-Token")
  valid_603620 = validateParameter(valid_603620, JString, required = false,
                                 default = nil)
  if valid_603620 != nil:
    section.add "X-Amz-Security-Token", valid_603620
  var valid_603621 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603621 = validateParameter(valid_603621, JString, required = false,
                                 default = nil)
  if valid_603621 != nil:
    section.add "X-Amz-Content-Sha256", valid_603621
  var valid_603622 = header.getOrDefault("X-Amz-Algorithm")
  valid_603622 = validateParameter(valid_603622, JString, required = false,
                                 default = nil)
  if valid_603622 != nil:
    section.add "X-Amz-Algorithm", valid_603622
  var valid_603623 = header.getOrDefault("X-Amz-Signature")
  valid_603623 = validateParameter(valid_603623, JString, required = false,
                                 default = nil)
  if valid_603623 != nil:
    section.add "X-Amz-Signature", valid_603623
  var valid_603624 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603624 = validateParameter(valid_603624, JString, required = false,
                                 default = nil)
  if valid_603624 != nil:
    section.add "X-Amz-SignedHeaders", valid_603624
  var valid_603625 = header.getOrDefault("X-Amz-Credential")
  valid_603625 = validateParameter(valid_603625, JString, required = false,
                                 default = nil)
  if valid_603625 != nil:
    section.add "X-Amz-Credential", valid_603625
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603626: Call_GetUpdateDefaultSearchField_603612; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the default search field for the search domain. The default search field is the text field that is searched when a search request does not specify which fields to search. By default, it is configured to include the contents of all of the domain's text fields. 
  ## 
  let valid = call_603626.validator(path, query, header, formData, body)
  let scheme = call_603626.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603626.url(scheme.get, call_603626.host, call_603626.base,
                         call_603626.route, valid.getOrDefault("path"))
  result = hook(call_603626, url, valid)

proc call*(call_603627: Call_GetUpdateDefaultSearchField_603612;
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
  var query_603628 = newJObject()
  add(query_603628, "Action", newJString(Action))
  add(query_603628, "DomainName", newJString(DomainName))
  add(query_603628, "DefaultSearchField", newJString(DefaultSearchField))
  add(query_603628, "Version", newJString(Version))
  result = call_603627.call(nil, query_603628, nil, nil, nil)

var getUpdateDefaultSearchField* = Call_GetUpdateDefaultSearchField_603612(
    name: "getUpdateDefaultSearchField", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateDefaultSearchField",
    validator: validate_GetUpdateDefaultSearchField_603613, base: "/",
    url: url_GetUpdateDefaultSearchField_603614,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateServiceAccessPolicies_603664 = ref object of OpenApiRestCall_602433
proc url_PostUpdateServiceAccessPolicies_603666(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostUpdateServiceAccessPolicies_603665(path: JsonNode;
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
  var valid_603667 = query.getOrDefault("Action")
  valid_603667 = validateParameter(valid_603667, JString, required = true, default = newJString(
      "UpdateServiceAccessPolicies"))
  if valid_603667 != nil:
    section.add "Action", valid_603667
  var valid_603668 = query.getOrDefault("Version")
  valid_603668 = validateParameter(valid_603668, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_603668 != nil:
    section.add "Version", valid_603668
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
  var valid_603669 = header.getOrDefault("X-Amz-Date")
  valid_603669 = validateParameter(valid_603669, JString, required = false,
                                 default = nil)
  if valid_603669 != nil:
    section.add "X-Amz-Date", valid_603669
  var valid_603670 = header.getOrDefault("X-Amz-Security-Token")
  valid_603670 = validateParameter(valid_603670, JString, required = false,
                                 default = nil)
  if valid_603670 != nil:
    section.add "X-Amz-Security-Token", valid_603670
  var valid_603671 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603671 = validateParameter(valid_603671, JString, required = false,
                                 default = nil)
  if valid_603671 != nil:
    section.add "X-Amz-Content-Sha256", valid_603671
  var valid_603672 = header.getOrDefault("X-Amz-Algorithm")
  valid_603672 = validateParameter(valid_603672, JString, required = false,
                                 default = nil)
  if valid_603672 != nil:
    section.add "X-Amz-Algorithm", valid_603672
  var valid_603673 = header.getOrDefault("X-Amz-Signature")
  valid_603673 = validateParameter(valid_603673, JString, required = false,
                                 default = nil)
  if valid_603673 != nil:
    section.add "X-Amz-Signature", valid_603673
  var valid_603674 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603674 = validateParameter(valid_603674, JString, required = false,
                                 default = nil)
  if valid_603674 != nil:
    section.add "X-Amz-SignedHeaders", valid_603674
  var valid_603675 = header.getOrDefault("X-Amz-Credential")
  valid_603675 = validateParameter(valid_603675, JString, required = false,
                                 default = nil)
  if valid_603675 != nil:
    section.add "X-Amz-Credential", valid_603675
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
  var valid_603676 = formData.getOrDefault("DomainName")
  valid_603676 = validateParameter(valid_603676, JString, required = true,
                                 default = nil)
  if valid_603676 != nil:
    section.add "DomainName", valid_603676
  var valid_603677 = formData.getOrDefault("AccessPolicies")
  valid_603677 = validateParameter(valid_603677, JString, required = true,
                                 default = nil)
  if valid_603677 != nil:
    section.add "AccessPolicies", valid_603677
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603678: Call_PostUpdateServiceAccessPolicies_603664;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Configures the policies that control access to the domain's document and search services. The maximum size of an access policy document is 100 KB.
  ## 
  let valid = call_603678.validator(path, query, header, formData, body)
  let scheme = call_603678.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603678.url(scheme.get, call_603678.host, call_603678.base,
                         call_603678.route, valid.getOrDefault("path"))
  result = hook(call_603678, url, valid)

proc call*(call_603679: Call_PostUpdateServiceAccessPolicies_603664;
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
  var query_603680 = newJObject()
  var formData_603681 = newJObject()
  add(formData_603681, "DomainName", newJString(DomainName))
  add(formData_603681, "AccessPolicies", newJString(AccessPolicies))
  add(query_603680, "Action", newJString(Action))
  add(query_603680, "Version", newJString(Version))
  result = call_603679.call(nil, query_603680, nil, formData_603681, nil)

var postUpdateServiceAccessPolicies* = Call_PostUpdateServiceAccessPolicies_603664(
    name: "postUpdateServiceAccessPolicies", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateServiceAccessPolicies",
    validator: validate_PostUpdateServiceAccessPolicies_603665, base: "/",
    url: url_PostUpdateServiceAccessPolicies_603666,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateServiceAccessPolicies_603647 = ref object of OpenApiRestCall_602433
proc url_GetUpdateServiceAccessPolicies_603649(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetUpdateServiceAccessPolicies_603648(path: JsonNode;
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
  var valid_603650 = query.getOrDefault("Action")
  valid_603650 = validateParameter(valid_603650, JString, required = true, default = newJString(
      "UpdateServiceAccessPolicies"))
  if valid_603650 != nil:
    section.add "Action", valid_603650
  var valid_603651 = query.getOrDefault("AccessPolicies")
  valid_603651 = validateParameter(valid_603651, JString, required = true,
                                 default = nil)
  if valid_603651 != nil:
    section.add "AccessPolicies", valid_603651
  var valid_603652 = query.getOrDefault("DomainName")
  valid_603652 = validateParameter(valid_603652, JString, required = true,
                                 default = nil)
  if valid_603652 != nil:
    section.add "DomainName", valid_603652
  var valid_603653 = query.getOrDefault("Version")
  valid_603653 = validateParameter(valid_603653, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_603653 != nil:
    section.add "Version", valid_603653
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
  var valid_603654 = header.getOrDefault("X-Amz-Date")
  valid_603654 = validateParameter(valid_603654, JString, required = false,
                                 default = nil)
  if valid_603654 != nil:
    section.add "X-Amz-Date", valid_603654
  var valid_603655 = header.getOrDefault("X-Amz-Security-Token")
  valid_603655 = validateParameter(valid_603655, JString, required = false,
                                 default = nil)
  if valid_603655 != nil:
    section.add "X-Amz-Security-Token", valid_603655
  var valid_603656 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603656 = validateParameter(valid_603656, JString, required = false,
                                 default = nil)
  if valid_603656 != nil:
    section.add "X-Amz-Content-Sha256", valid_603656
  var valid_603657 = header.getOrDefault("X-Amz-Algorithm")
  valid_603657 = validateParameter(valid_603657, JString, required = false,
                                 default = nil)
  if valid_603657 != nil:
    section.add "X-Amz-Algorithm", valid_603657
  var valid_603658 = header.getOrDefault("X-Amz-Signature")
  valid_603658 = validateParameter(valid_603658, JString, required = false,
                                 default = nil)
  if valid_603658 != nil:
    section.add "X-Amz-Signature", valid_603658
  var valid_603659 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603659 = validateParameter(valid_603659, JString, required = false,
                                 default = nil)
  if valid_603659 != nil:
    section.add "X-Amz-SignedHeaders", valid_603659
  var valid_603660 = header.getOrDefault("X-Amz-Credential")
  valid_603660 = validateParameter(valid_603660, JString, required = false,
                                 default = nil)
  if valid_603660 != nil:
    section.add "X-Amz-Credential", valid_603660
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603661: Call_GetUpdateServiceAccessPolicies_603647; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the policies that control access to the domain's document and search services. The maximum size of an access policy document is 100 KB.
  ## 
  let valid = call_603661.validator(path, query, header, formData, body)
  let scheme = call_603661.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603661.url(scheme.get, call_603661.host, call_603661.base,
                         call_603661.route, valid.getOrDefault("path"))
  result = hook(call_603661, url, valid)

proc call*(call_603662: Call_GetUpdateServiceAccessPolicies_603647;
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
  var query_603663 = newJObject()
  add(query_603663, "Action", newJString(Action))
  add(query_603663, "AccessPolicies", newJString(AccessPolicies))
  add(query_603663, "DomainName", newJString(DomainName))
  add(query_603663, "Version", newJString(Version))
  result = call_603662.call(nil, query_603663, nil, nil, nil)

var getUpdateServiceAccessPolicies* = Call_GetUpdateServiceAccessPolicies_603647(
    name: "getUpdateServiceAccessPolicies", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateServiceAccessPolicies",
    validator: validate_GetUpdateServiceAccessPolicies_603648, base: "/",
    url: url_GetUpdateServiceAccessPolicies_603649,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateStemmingOptions_603699 = ref object of OpenApiRestCall_602433
proc url_PostUpdateStemmingOptions_603701(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostUpdateStemmingOptions_603700(path: JsonNode; query: JsonNode;
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
  var valid_603702 = query.getOrDefault("Action")
  valid_603702 = validateParameter(valid_603702, JString, required = true,
                                 default = newJString("UpdateStemmingOptions"))
  if valid_603702 != nil:
    section.add "Action", valid_603702
  var valid_603703 = query.getOrDefault("Version")
  valid_603703 = validateParameter(valid_603703, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_603703 != nil:
    section.add "Version", valid_603703
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
  var valid_603704 = header.getOrDefault("X-Amz-Date")
  valid_603704 = validateParameter(valid_603704, JString, required = false,
                                 default = nil)
  if valid_603704 != nil:
    section.add "X-Amz-Date", valid_603704
  var valid_603705 = header.getOrDefault("X-Amz-Security-Token")
  valid_603705 = validateParameter(valid_603705, JString, required = false,
                                 default = nil)
  if valid_603705 != nil:
    section.add "X-Amz-Security-Token", valid_603705
  var valid_603706 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603706 = validateParameter(valid_603706, JString, required = false,
                                 default = nil)
  if valid_603706 != nil:
    section.add "X-Amz-Content-Sha256", valid_603706
  var valid_603707 = header.getOrDefault("X-Amz-Algorithm")
  valid_603707 = validateParameter(valid_603707, JString, required = false,
                                 default = nil)
  if valid_603707 != nil:
    section.add "X-Amz-Algorithm", valid_603707
  var valid_603708 = header.getOrDefault("X-Amz-Signature")
  valid_603708 = validateParameter(valid_603708, JString, required = false,
                                 default = nil)
  if valid_603708 != nil:
    section.add "X-Amz-Signature", valid_603708
  var valid_603709 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603709 = validateParameter(valid_603709, JString, required = false,
                                 default = nil)
  if valid_603709 != nil:
    section.add "X-Amz-SignedHeaders", valid_603709
  var valid_603710 = header.getOrDefault("X-Amz-Credential")
  valid_603710 = validateParameter(valid_603710, JString, required = false,
                                 default = nil)
  if valid_603710 != nil:
    section.add "X-Amz-Credential", valid_603710
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Stems: JString (required)
  ##        : Maps terms to their stems, serialized as a JSON document. The document has a single object with one property "stems" whose value is an object mapping terms to their stems. The maximum size of a stemming document is 500 KB. Example: <code>{ "stems": {"people": "person", "walking": "walk"} }</code>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_603711 = formData.getOrDefault("DomainName")
  valid_603711 = validateParameter(valid_603711, JString, required = true,
                                 default = nil)
  if valid_603711 != nil:
    section.add "DomainName", valid_603711
  var valid_603712 = formData.getOrDefault("Stems")
  valid_603712 = validateParameter(valid_603712, JString, required = true,
                                 default = nil)
  if valid_603712 != nil:
    section.add "Stems", valid_603712
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603713: Call_PostUpdateStemmingOptions_603699; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a stemming dictionary for the search domain. The stemming dictionary is used during indexing and when processing search requests. The maximum size of the stemming dictionary is 500 KB.
  ## 
  let valid = call_603713.validator(path, query, header, formData, body)
  let scheme = call_603713.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603713.url(scheme.get, call_603713.host, call_603713.base,
                         call_603713.route, valid.getOrDefault("path"))
  result = hook(call_603713, url, valid)

proc call*(call_603714: Call_PostUpdateStemmingOptions_603699; DomainName: string;
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
  var query_603715 = newJObject()
  var formData_603716 = newJObject()
  add(formData_603716, "DomainName", newJString(DomainName))
  add(query_603715, "Action", newJString(Action))
  add(formData_603716, "Stems", newJString(Stems))
  add(query_603715, "Version", newJString(Version))
  result = call_603714.call(nil, query_603715, nil, formData_603716, nil)

var postUpdateStemmingOptions* = Call_PostUpdateStemmingOptions_603699(
    name: "postUpdateStemmingOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateStemmingOptions",
    validator: validate_PostUpdateStemmingOptions_603700, base: "/",
    url: url_PostUpdateStemmingOptions_603701,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateStemmingOptions_603682 = ref object of OpenApiRestCall_602433
proc url_GetUpdateStemmingOptions_603684(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetUpdateStemmingOptions_603683(path: JsonNode; query: JsonNode;
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
  var valid_603685 = query.getOrDefault("Action")
  valid_603685 = validateParameter(valid_603685, JString, required = true,
                                 default = newJString("UpdateStemmingOptions"))
  if valid_603685 != nil:
    section.add "Action", valid_603685
  var valid_603686 = query.getOrDefault("Stems")
  valid_603686 = validateParameter(valid_603686, JString, required = true,
                                 default = nil)
  if valid_603686 != nil:
    section.add "Stems", valid_603686
  var valid_603687 = query.getOrDefault("DomainName")
  valid_603687 = validateParameter(valid_603687, JString, required = true,
                                 default = nil)
  if valid_603687 != nil:
    section.add "DomainName", valid_603687
  var valid_603688 = query.getOrDefault("Version")
  valid_603688 = validateParameter(valid_603688, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_603688 != nil:
    section.add "Version", valid_603688
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
  var valid_603689 = header.getOrDefault("X-Amz-Date")
  valid_603689 = validateParameter(valid_603689, JString, required = false,
                                 default = nil)
  if valid_603689 != nil:
    section.add "X-Amz-Date", valid_603689
  var valid_603690 = header.getOrDefault("X-Amz-Security-Token")
  valid_603690 = validateParameter(valid_603690, JString, required = false,
                                 default = nil)
  if valid_603690 != nil:
    section.add "X-Amz-Security-Token", valid_603690
  var valid_603691 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603691 = validateParameter(valid_603691, JString, required = false,
                                 default = nil)
  if valid_603691 != nil:
    section.add "X-Amz-Content-Sha256", valid_603691
  var valid_603692 = header.getOrDefault("X-Amz-Algorithm")
  valid_603692 = validateParameter(valid_603692, JString, required = false,
                                 default = nil)
  if valid_603692 != nil:
    section.add "X-Amz-Algorithm", valid_603692
  var valid_603693 = header.getOrDefault("X-Amz-Signature")
  valid_603693 = validateParameter(valid_603693, JString, required = false,
                                 default = nil)
  if valid_603693 != nil:
    section.add "X-Amz-Signature", valid_603693
  var valid_603694 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603694 = validateParameter(valid_603694, JString, required = false,
                                 default = nil)
  if valid_603694 != nil:
    section.add "X-Amz-SignedHeaders", valid_603694
  var valid_603695 = header.getOrDefault("X-Amz-Credential")
  valid_603695 = validateParameter(valid_603695, JString, required = false,
                                 default = nil)
  if valid_603695 != nil:
    section.add "X-Amz-Credential", valid_603695
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603696: Call_GetUpdateStemmingOptions_603682; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a stemming dictionary for the search domain. The stemming dictionary is used during indexing and when processing search requests. The maximum size of the stemming dictionary is 500 KB.
  ## 
  let valid = call_603696.validator(path, query, header, formData, body)
  let scheme = call_603696.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603696.url(scheme.get, call_603696.host, call_603696.base,
                         call_603696.route, valid.getOrDefault("path"))
  result = hook(call_603696, url, valid)

proc call*(call_603697: Call_GetUpdateStemmingOptions_603682; Stems: string;
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
  var query_603698 = newJObject()
  add(query_603698, "Action", newJString(Action))
  add(query_603698, "Stems", newJString(Stems))
  add(query_603698, "DomainName", newJString(DomainName))
  add(query_603698, "Version", newJString(Version))
  result = call_603697.call(nil, query_603698, nil, nil, nil)

var getUpdateStemmingOptions* = Call_GetUpdateStemmingOptions_603682(
    name: "getUpdateStemmingOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateStemmingOptions",
    validator: validate_GetUpdateStemmingOptions_603683, base: "/",
    url: url_GetUpdateStemmingOptions_603684, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateStopwordOptions_603734 = ref object of OpenApiRestCall_602433
proc url_PostUpdateStopwordOptions_603736(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostUpdateStopwordOptions_603735(path: JsonNode; query: JsonNode;
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
  var valid_603737 = query.getOrDefault("Action")
  valid_603737 = validateParameter(valid_603737, JString, required = true,
                                 default = newJString("UpdateStopwordOptions"))
  if valid_603737 != nil:
    section.add "Action", valid_603737
  var valid_603738 = query.getOrDefault("Version")
  valid_603738 = validateParameter(valid_603738, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_603738 != nil:
    section.add "Version", valid_603738
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
  var valid_603739 = header.getOrDefault("X-Amz-Date")
  valid_603739 = validateParameter(valid_603739, JString, required = false,
                                 default = nil)
  if valid_603739 != nil:
    section.add "X-Amz-Date", valid_603739
  var valid_603740 = header.getOrDefault("X-Amz-Security-Token")
  valid_603740 = validateParameter(valid_603740, JString, required = false,
                                 default = nil)
  if valid_603740 != nil:
    section.add "X-Amz-Security-Token", valid_603740
  var valid_603741 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603741 = validateParameter(valid_603741, JString, required = false,
                                 default = nil)
  if valid_603741 != nil:
    section.add "X-Amz-Content-Sha256", valid_603741
  var valid_603742 = header.getOrDefault("X-Amz-Algorithm")
  valid_603742 = validateParameter(valid_603742, JString, required = false,
                                 default = nil)
  if valid_603742 != nil:
    section.add "X-Amz-Algorithm", valid_603742
  var valid_603743 = header.getOrDefault("X-Amz-Signature")
  valid_603743 = validateParameter(valid_603743, JString, required = false,
                                 default = nil)
  if valid_603743 != nil:
    section.add "X-Amz-Signature", valid_603743
  var valid_603744 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603744 = validateParameter(valid_603744, JString, required = false,
                                 default = nil)
  if valid_603744 != nil:
    section.add "X-Amz-SignedHeaders", valid_603744
  var valid_603745 = header.getOrDefault("X-Amz-Credential")
  valid_603745 = validateParameter(valid_603745, JString, required = false,
                                 default = nil)
  if valid_603745 != nil:
    section.add "X-Amz-Credential", valid_603745
  result.add "header", section
  ## parameters in `formData` object:
  ##   Stopwords: JString (required)
  ##            : Lists stopwords serialized as a JSON document. The document has a single object with one property "stopwords" whose value is an array of strings. The maximum size of a stopwords document is 10 KB. Example: <code>{ "stopwords": ["a", "an", "the", "of"] }</code>
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Stopwords` field"
  var valid_603746 = formData.getOrDefault("Stopwords")
  valid_603746 = validateParameter(valid_603746, JString, required = true,
                                 default = nil)
  if valid_603746 != nil:
    section.add "Stopwords", valid_603746
  var valid_603747 = formData.getOrDefault("DomainName")
  valid_603747 = validateParameter(valid_603747, JString, required = true,
                                 default = nil)
  if valid_603747 != nil:
    section.add "DomainName", valid_603747
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603748: Call_PostUpdateStopwordOptions_603734; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures stopwords for the search domain. Stopwords are used during indexing and when processing search requests. The maximum size of the stopwords dictionary is 10 KB.
  ## 
  let valid = call_603748.validator(path, query, header, formData, body)
  let scheme = call_603748.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603748.url(scheme.get, call_603748.host, call_603748.base,
                         call_603748.route, valid.getOrDefault("path"))
  result = hook(call_603748, url, valid)

proc call*(call_603749: Call_PostUpdateStopwordOptions_603734; Stopwords: string;
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
  var query_603750 = newJObject()
  var formData_603751 = newJObject()
  add(formData_603751, "Stopwords", newJString(Stopwords))
  add(formData_603751, "DomainName", newJString(DomainName))
  add(query_603750, "Action", newJString(Action))
  add(query_603750, "Version", newJString(Version))
  result = call_603749.call(nil, query_603750, nil, formData_603751, nil)

var postUpdateStopwordOptions* = Call_PostUpdateStopwordOptions_603734(
    name: "postUpdateStopwordOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateStopwordOptions",
    validator: validate_PostUpdateStopwordOptions_603735, base: "/",
    url: url_PostUpdateStopwordOptions_603736,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateStopwordOptions_603717 = ref object of OpenApiRestCall_602433
proc url_GetUpdateStopwordOptions_603719(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetUpdateStopwordOptions_603718(path: JsonNode; query: JsonNode;
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
  var valid_603720 = query.getOrDefault("Action")
  valid_603720 = validateParameter(valid_603720, JString, required = true,
                                 default = newJString("UpdateStopwordOptions"))
  if valid_603720 != nil:
    section.add "Action", valid_603720
  var valid_603721 = query.getOrDefault("Stopwords")
  valid_603721 = validateParameter(valid_603721, JString, required = true,
                                 default = nil)
  if valid_603721 != nil:
    section.add "Stopwords", valid_603721
  var valid_603722 = query.getOrDefault("DomainName")
  valid_603722 = validateParameter(valid_603722, JString, required = true,
                                 default = nil)
  if valid_603722 != nil:
    section.add "DomainName", valid_603722
  var valid_603723 = query.getOrDefault("Version")
  valid_603723 = validateParameter(valid_603723, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_603723 != nil:
    section.add "Version", valid_603723
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
  var valid_603724 = header.getOrDefault("X-Amz-Date")
  valid_603724 = validateParameter(valid_603724, JString, required = false,
                                 default = nil)
  if valid_603724 != nil:
    section.add "X-Amz-Date", valid_603724
  var valid_603725 = header.getOrDefault("X-Amz-Security-Token")
  valid_603725 = validateParameter(valid_603725, JString, required = false,
                                 default = nil)
  if valid_603725 != nil:
    section.add "X-Amz-Security-Token", valid_603725
  var valid_603726 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603726 = validateParameter(valid_603726, JString, required = false,
                                 default = nil)
  if valid_603726 != nil:
    section.add "X-Amz-Content-Sha256", valid_603726
  var valid_603727 = header.getOrDefault("X-Amz-Algorithm")
  valid_603727 = validateParameter(valid_603727, JString, required = false,
                                 default = nil)
  if valid_603727 != nil:
    section.add "X-Amz-Algorithm", valid_603727
  var valid_603728 = header.getOrDefault("X-Amz-Signature")
  valid_603728 = validateParameter(valid_603728, JString, required = false,
                                 default = nil)
  if valid_603728 != nil:
    section.add "X-Amz-Signature", valid_603728
  var valid_603729 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603729 = validateParameter(valid_603729, JString, required = false,
                                 default = nil)
  if valid_603729 != nil:
    section.add "X-Amz-SignedHeaders", valid_603729
  var valid_603730 = header.getOrDefault("X-Amz-Credential")
  valid_603730 = validateParameter(valid_603730, JString, required = false,
                                 default = nil)
  if valid_603730 != nil:
    section.add "X-Amz-Credential", valid_603730
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603731: Call_GetUpdateStopwordOptions_603717; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures stopwords for the search domain. Stopwords are used during indexing and when processing search requests. The maximum size of the stopwords dictionary is 10 KB.
  ## 
  let valid = call_603731.validator(path, query, header, formData, body)
  let scheme = call_603731.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603731.url(scheme.get, call_603731.host, call_603731.base,
                         call_603731.route, valid.getOrDefault("path"))
  result = hook(call_603731, url, valid)

proc call*(call_603732: Call_GetUpdateStopwordOptions_603717; Stopwords: string;
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
  var query_603733 = newJObject()
  add(query_603733, "Action", newJString(Action))
  add(query_603733, "Stopwords", newJString(Stopwords))
  add(query_603733, "DomainName", newJString(DomainName))
  add(query_603733, "Version", newJString(Version))
  result = call_603732.call(nil, query_603733, nil, nil, nil)

var getUpdateStopwordOptions* = Call_GetUpdateStopwordOptions_603717(
    name: "getUpdateStopwordOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateStopwordOptions",
    validator: validate_GetUpdateStopwordOptions_603718, base: "/",
    url: url_GetUpdateStopwordOptions_603719, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateSynonymOptions_603769 = ref object of OpenApiRestCall_602433
proc url_PostUpdateSynonymOptions_603771(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostUpdateSynonymOptions_603770(path: JsonNode; query: JsonNode;
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
  var valid_603772 = query.getOrDefault("Action")
  valid_603772 = validateParameter(valid_603772, JString, required = true,
                                 default = newJString("UpdateSynonymOptions"))
  if valid_603772 != nil:
    section.add "Action", valid_603772
  var valid_603773 = query.getOrDefault("Version")
  valid_603773 = validateParameter(valid_603773, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_603773 != nil:
    section.add "Version", valid_603773
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
  var valid_603774 = header.getOrDefault("X-Amz-Date")
  valid_603774 = validateParameter(valid_603774, JString, required = false,
                                 default = nil)
  if valid_603774 != nil:
    section.add "X-Amz-Date", valid_603774
  var valid_603775 = header.getOrDefault("X-Amz-Security-Token")
  valid_603775 = validateParameter(valid_603775, JString, required = false,
                                 default = nil)
  if valid_603775 != nil:
    section.add "X-Amz-Security-Token", valid_603775
  var valid_603776 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603776 = validateParameter(valid_603776, JString, required = false,
                                 default = nil)
  if valid_603776 != nil:
    section.add "X-Amz-Content-Sha256", valid_603776
  var valid_603777 = header.getOrDefault("X-Amz-Algorithm")
  valid_603777 = validateParameter(valid_603777, JString, required = false,
                                 default = nil)
  if valid_603777 != nil:
    section.add "X-Amz-Algorithm", valid_603777
  var valid_603778 = header.getOrDefault("X-Amz-Signature")
  valid_603778 = validateParameter(valid_603778, JString, required = false,
                                 default = nil)
  if valid_603778 != nil:
    section.add "X-Amz-Signature", valid_603778
  var valid_603779 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603779 = validateParameter(valid_603779, JString, required = false,
                                 default = nil)
  if valid_603779 != nil:
    section.add "X-Amz-SignedHeaders", valid_603779
  var valid_603780 = header.getOrDefault("X-Amz-Credential")
  valid_603780 = validateParameter(valid_603780, JString, required = false,
                                 default = nil)
  if valid_603780 != nil:
    section.add "X-Amz-Credential", valid_603780
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Synonyms: JString (required)
  ##           : Maps terms to their synonyms, serialized as a JSON document. The document has a single object with one property "synonyms" whose value is an object mapping terms to their synonyms. Each synonym is a simple string or an array of strings. The maximum size of a stopwords document is 100 KB. Example: <code>{ "synonyms": {"cat": ["feline", "kitten"], "puppy": "dog"} }</code>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_603781 = formData.getOrDefault("DomainName")
  valid_603781 = validateParameter(valid_603781, JString, required = true,
                                 default = nil)
  if valid_603781 != nil:
    section.add "DomainName", valid_603781
  var valid_603782 = formData.getOrDefault("Synonyms")
  valid_603782 = validateParameter(valid_603782, JString, required = true,
                                 default = nil)
  if valid_603782 != nil:
    section.add "Synonyms", valid_603782
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603783: Call_PostUpdateSynonymOptions_603769; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a synonym dictionary for the search domain. The synonym dictionary is used during indexing to configure mappings for terms that occur in text fields. The maximum size of the synonym dictionary is 100 KB. 
  ## 
  let valid = call_603783.validator(path, query, header, formData, body)
  let scheme = call_603783.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603783.url(scheme.get, call_603783.host, call_603783.base,
                         call_603783.route, valid.getOrDefault("path"))
  result = hook(call_603783, url, valid)

proc call*(call_603784: Call_PostUpdateSynonymOptions_603769; DomainName: string;
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
  var query_603785 = newJObject()
  var formData_603786 = newJObject()
  add(formData_603786, "DomainName", newJString(DomainName))
  add(formData_603786, "Synonyms", newJString(Synonyms))
  add(query_603785, "Action", newJString(Action))
  add(query_603785, "Version", newJString(Version))
  result = call_603784.call(nil, query_603785, nil, formData_603786, nil)

var postUpdateSynonymOptions* = Call_PostUpdateSynonymOptions_603769(
    name: "postUpdateSynonymOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateSynonymOptions",
    validator: validate_PostUpdateSynonymOptions_603770, base: "/",
    url: url_PostUpdateSynonymOptions_603771, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateSynonymOptions_603752 = ref object of OpenApiRestCall_602433
proc url_GetUpdateSynonymOptions_603754(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetUpdateSynonymOptions_603753(path: JsonNode; query: JsonNode;
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
  var valid_603755 = query.getOrDefault("Action")
  valid_603755 = validateParameter(valid_603755, JString, required = true,
                                 default = newJString("UpdateSynonymOptions"))
  if valid_603755 != nil:
    section.add "Action", valid_603755
  var valid_603756 = query.getOrDefault("Synonyms")
  valid_603756 = validateParameter(valid_603756, JString, required = true,
                                 default = nil)
  if valid_603756 != nil:
    section.add "Synonyms", valid_603756
  var valid_603757 = query.getOrDefault("DomainName")
  valid_603757 = validateParameter(valid_603757, JString, required = true,
                                 default = nil)
  if valid_603757 != nil:
    section.add "DomainName", valid_603757
  var valid_603758 = query.getOrDefault("Version")
  valid_603758 = validateParameter(valid_603758, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_603758 != nil:
    section.add "Version", valid_603758
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
  var valid_603759 = header.getOrDefault("X-Amz-Date")
  valid_603759 = validateParameter(valid_603759, JString, required = false,
                                 default = nil)
  if valid_603759 != nil:
    section.add "X-Amz-Date", valid_603759
  var valid_603760 = header.getOrDefault("X-Amz-Security-Token")
  valid_603760 = validateParameter(valid_603760, JString, required = false,
                                 default = nil)
  if valid_603760 != nil:
    section.add "X-Amz-Security-Token", valid_603760
  var valid_603761 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_603761 = validateParameter(valid_603761, JString, required = false,
                                 default = nil)
  if valid_603761 != nil:
    section.add "X-Amz-Content-Sha256", valid_603761
  var valid_603762 = header.getOrDefault("X-Amz-Algorithm")
  valid_603762 = validateParameter(valid_603762, JString, required = false,
                                 default = nil)
  if valid_603762 != nil:
    section.add "X-Amz-Algorithm", valid_603762
  var valid_603763 = header.getOrDefault("X-Amz-Signature")
  valid_603763 = validateParameter(valid_603763, JString, required = false,
                                 default = nil)
  if valid_603763 != nil:
    section.add "X-Amz-Signature", valid_603763
  var valid_603764 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_603764 = validateParameter(valid_603764, JString, required = false,
                                 default = nil)
  if valid_603764 != nil:
    section.add "X-Amz-SignedHeaders", valid_603764
  var valid_603765 = header.getOrDefault("X-Amz-Credential")
  valid_603765 = validateParameter(valid_603765, JString, required = false,
                                 default = nil)
  if valid_603765 != nil:
    section.add "X-Amz-Credential", valid_603765
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_603766: Call_GetUpdateSynonymOptions_603752; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a synonym dictionary for the search domain. The synonym dictionary is used during indexing to configure mappings for terms that occur in text fields. The maximum size of the synonym dictionary is 100 KB. 
  ## 
  let valid = call_603766.validator(path, query, header, formData, body)
  let scheme = call_603766.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_603766.url(scheme.get, call_603766.host, call_603766.base,
                         call_603766.route, valid.getOrDefault("path"))
  result = hook(call_603766, url, valid)

proc call*(call_603767: Call_GetUpdateSynonymOptions_603752; Synonyms: string;
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
  var query_603768 = newJObject()
  add(query_603768, "Action", newJString(Action))
  add(query_603768, "Synonyms", newJString(Synonyms))
  add(query_603768, "DomainName", newJString(DomainName))
  add(query_603768, "Version", newJString(Version))
  result = call_603767.call(nil, query_603768, nil, nil, nil)

var getUpdateSynonymOptions* = Call_GetUpdateSynonymOptions_603752(
    name: "getUpdateSynonymOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateSynonymOptions",
    validator: validate_GetUpdateSynonymOptions_603753, base: "/",
    url: url_GetUpdateSynonymOptions_603754, schemes: {Scheme.Https, Scheme.Http})
export
  rest

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
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)
