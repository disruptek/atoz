
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

  OpenApiRestCall_600426 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_600426](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_600426): Option[Scheme] {.used.} =
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
  Call_PostCreateDomain_601039 = ref object of OpenApiRestCall_600426
proc url_PostCreateDomain_601041(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostCreateDomain_601040(path: JsonNode; query: JsonNode;
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
  var valid_601042 = query.getOrDefault("Action")
  valid_601042 = validateParameter(valid_601042, JString, required = true,
                                 default = newJString("CreateDomain"))
  if valid_601042 != nil:
    section.add "Action", valid_601042
  var valid_601043 = query.getOrDefault("Version")
  valid_601043 = validateParameter(valid_601043, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_601043 != nil:
    section.add "Version", valid_601043
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
  var valid_601044 = header.getOrDefault("X-Amz-Date")
  valid_601044 = validateParameter(valid_601044, JString, required = false,
                                 default = nil)
  if valid_601044 != nil:
    section.add "X-Amz-Date", valid_601044
  var valid_601045 = header.getOrDefault("X-Amz-Security-Token")
  valid_601045 = validateParameter(valid_601045, JString, required = false,
                                 default = nil)
  if valid_601045 != nil:
    section.add "X-Amz-Security-Token", valid_601045
  var valid_601046 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601046 = validateParameter(valid_601046, JString, required = false,
                                 default = nil)
  if valid_601046 != nil:
    section.add "X-Amz-Content-Sha256", valid_601046
  var valid_601047 = header.getOrDefault("X-Amz-Algorithm")
  valid_601047 = validateParameter(valid_601047, JString, required = false,
                                 default = nil)
  if valid_601047 != nil:
    section.add "X-Amz-Algorithm", valid_601047
  var valid_601048 = header.getOrDefault("X-Amz-Signature")
  valid_601048 = validateParameter(valid_601048, JString, required = false,
                                 default = nil)
  if valid_601048 != nil:
    section.add "X-Amz-Signature", valid_601048
  var valid_601049 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601049 = validateParameter(valid_601049, JString, required = false,
                                 default = nil)
  if valid_601049 != nil:
    section.add "X-Amz-SignedHeaders", valid_601049
  var valid_601050 = header.getOrDefault("X-Amz-Credential")
  valid_601050 = validateParameter(valid_601050, JString, required = false,
                                 default = nil)
  if valid_601050 != nil:
    section.add "X-Amz-Credential", valid_601050
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_601051 = formData.getOrDefault("DomainName")
  valid_601051 = validateParameter(valid_601051, JString, required = true,
                                 default = nil)
  if valid_601051 != nil:
    section.add "DomainName", valid_601051
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601052: Call_PostCreateDomain_601039; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new search domain.
  ## 
  let valid = call_601052.validator(path, query, header, formData, body)
  let scheme = call_601052.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601052.url(scheme.get, call_601052.host, call_601052.base,
                         call_601052.route, valid.getOrDefault("path"))
  result = hook(call_601052, url, valid)

proc call*(call_601053: Call_PostCreateDomain_601039; DomainName: string;
          Action: string = "CreateDomain"; Version: string = "2011-02-01"): Recallable =
  ## postCreateDomain
  ## Creates a new search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601054 = newJObject()
  var formData_601055 = newJObject()
  add(formData_601055, "DomainName", newJString(DomainName))
  add(query_601054, "Action", newJString(Action))
  add(query_601054, "Version", newJString(Version))
  result = call_601053.call(nil, query_601054, nil, formData_601055, nil)

var postCreateDomain* = Call_PostCreateDomain_601039(name: "postCreateDomain",
    meth: HttpMethod.HttpPost, host: "cloudsearch.amazonaws.com",
    route: "/#Action=CreateDomain", validator: validate_PostCreateDomain_601040,
    base: "/", url: url_PostCreateDomain_601041,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDomain_600768 = ref object of OpenApiRestCall_600426
proc url_GetCreateDomain_600770(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetCreateDomain_600769(path: JsonNode; query: JsonNode;
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
  var valid_600895 = query.getOrDefault("Action")
  valid_600895 = validateParameter(valid_600895, JString, required = true,
                                 default = newJString("CreateDomain"))
  if valid_600895 != nil:
    section.add "Action", valid_600895
  var valid_600896 = query.getOrDefault("DomainName")
  valid_600896 = validateParameter(valid_600896, JString, required = true,
                                 default = nil)
  if valid_600896 != nil:
    section.add "DomainName", valid_600896
  var valid_600897 = query.getOrDefault("Version")
  valid_600897 = validateParameter(valid_600897, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_600897 != nil:
    section.add "Version", valid_600897
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
  var valid_600898 = header.getOrDefault("X-Amz-Date")
  valid_600898 = validateParameter(valid_600898, JString, required = false,
                                 default = nil)
  if valid_600898 != nil:
    section.add "X-Amz-Date", valid_600898
  var valid_600899 = header.getOrDefault("X-Amz-Security-Token")
  valid_600899 = validateParameter(valid_600899, JString, required = false,
                                 default = nil)
  if valid_600899 != nil:
    section.add "X-Amz-Security-Token", valid_600899
  var valid_600900 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600900 = validateParameter(valid_600900, JString, required = false,
                                 default = nil)
  if valid_600900 != nil:
    section.add "X-Amz-Content-Sha256", valid_600900
  var valid_600901 = header.getOrDefault("X-Amz-Algorithm")
  valid_600901 = validateParameter(valid_600901, JString, required = false,
                                 default = nil)
  if valid_600901 != nil:
    section.add "X-Amz-Algorithm", valid_600901
  var valid_600902 = header.getOrDefault("X-Amz-Signature")
  valid_600902 = validateParameter(valid_600902, JString, required = false,
                                 default = nil)
  if valid_600902 != nil:
    section.add "X-Amz-Signature", valid_600902
  var valid_600903 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600903 = validateParameter(valid_600903, JString, required = false,
                                 default = nil)
  if valid_600903 != nil:
    section.add "X-Amz-SignedHeaders", valid_600903
  var valid_600904 = header.getOrDefault("X-Amz-Credential")
  valid_600904 = validateParameter(valid_600904, JString, required = false,
                                 default = nil)
  if valid_600904 != nil:
    section.add "X-Amz-Credential", valid_600904
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600927: Call_GetCreateDomain_600768; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new search domain.
  ## 
  let valid = call_600927.validator(path, query, header, formData, body)
  let scheme = call_600927.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600927.url(scheme.get, call_600927.host, call_600927.base,
                         call_600927.route, valid.getOrDefault("path"))
  result = hook(call_600927, url, valid)

proc call*(call_600998: Call_GetCreateDomain_600768; DomainName: string;
          Action: string = "CreateDomain"; Version: string = "2011-02-01"): Recallable =
  ## getCreateDomain
  ## Creates a new search domain.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_600999 = newJObject()
  add(query_600999, "Action", newJString(Action))
  add(query_600999, "DomainName", newJString(DomainName))
  add(query_600999, "Version", newJString(Version))
  result = call_600998.call(nil, query_600999, nil, nil, nil)

var getCreateDomain* = Call_GetCreateDomain_600768(name: "getCreateDomain",
    meth: HttpMethod.HttpGet, host: "cloudsearch.amazonaws.com",
    route: "/#Action=CreateDomain", validator: validate_GetCreateDomain_600769,
    base: "/", url: url_GetCreateDomain_600770, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDefineIndexField_601078 = ref object of OpenApiRestCall_600426
proc url_PostDefineIndexField_601080(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDefineIndexField_601079(path: JsonNode; query: JsonNode;
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
  var valid_601081 = query.getOrDefault("Action")
  valid_601081 = validateParameter(valid_601081, JString, required = true,
                                 default = newJString("DefineIndexField"))
  if valid_601081 != nil:
    section.add "Action", valid_601081
  var valid_601082 = query.getOrDefault("Version")
  valid_601082 = validateParameter(valid_601082, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_601082 != nil:
    section.add "Version", valid_601082
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
  var valid_601083 = header.getOrDefault("X-Amz-Date")
  valid_601083 = validateParameter(valid_601083, JString, required = false,
                                 default = nil)
  if valid_601083 != nil:
    section.add "X-Amz-Date", valid_601083
  var valid_601084 = header.getOrDefault("X-Amz-Security-Token")
  valid_601084 = validateParameter(valid_601084, JString, required = false,
                                 default = nil)
  if valid_601084 != nil:
    section.add "X-Amz-Security-Token", valid_601084
  var valid_601085 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601085 = validateParameter(valid_601085, JString, required = false,
                                 default = nil)
  if valid_601085 != nil:
    section.add "X-Amz-Content-Sha256", valid_601085
  var valid_601086 = header.getOrDefault("X-Amz-Algorithm")
  valid_601086 = validateParameter(valid_601086, JString, required = false,
                                 default = nil)
  if valid_601086 != nil:
    section.add "X-Amz-Algorithm", valid_601086
  var valid_601087 = header.getOrDefault("X-Amz-Signature")
  valid_601087 = validateParameter(valid_601087, JString, required = false,
                                 default = nil)
  if valid_601087 != nil:
    section.add "X-Amz-Signature", valid_601087
  var valid_601088 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601088 = validateParameter(valid_601088, JString, required = false,
                                 default = nil)
  if valid_601088 != nil:
    section.add "X-Amz-SignedHeaders", valid_601088
  var valid_601089 = header.getOrDefault("X-Amz-Credential")
  valid_601089 = validateParameter(valid_601089, JString, required = false,
                                 default = nil)
  if valid_601089 != nil:
    section.add "X-Amz-Credential", valid_601089
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
  var valid_601090 = formData.getOrDefault("IndexField.UIntOptions")
  valid_601090 = validateParameter(valid_601090, JString, required = false,
                                 default = nil)
  if valid_601090 != nil:
    section.add "IndexField.UIntOptions", valid_601090
  var valid_601091 = formData.getOrDefault("IndexField.TextOptions")
  valid_601091 = validateParameter(valid_601091, JString, required = false,
                                 default = nil)
  if valid_601091 != nil:
    section.add "IndexField.TextOptions", valid_601091
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_601092 = formData.getOrDefault("DomainName")
  valid_601092 = validateParameter(valid_601092, JString, required = true,
                                 default = nil)
  if valid_601092 != nil:
    section.add "DomainName", valid_601092
  var valid_601093 = formData.getOrDefault("IndexField.LiteralOptions")
  valid_601093 = validateParameter(valid_601093, JString, required = false,
                                 default = nil)
  if valid_601093 != nil:
    section.add "IndexField.LiteralOptions", valid_601093
  var valid_601094 = formData.getOrDefault("IndexField.IndexFieldType")
  valid_601094 = validateParameter(valid_601094, JString, required = false,
                                 default = nil)
  if valid_601094 != nil:
    section.add "IndexField.IndexFieldType", valid_601094
  var valid_601095 = formData.getOrDefault("IndexField.IndexFieldName")
  valid_601095 = validateParameter(valid_601095, JString, required = false,
                                 default = nil)
  if valid_601095 != nil:
    section.add "IndexField.IndexFieldName", valid_601095
  var valid_601096 = formData.getOrDefault("IndexField.SourceAttributes")
  valid_601096 = validateParameter(valid_601096, JArray, required = false,
                                 default = nil)
  if valid_601096 != nil:
    section.add "IndexField.SourceAttributes", valid_601096
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601097: Call_PostDefineIndexField_601078; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures an <code>IndexField</code> for the search domain. Used to create new fields and modify existing ones. If the field exists, the new configuration replaces the old one. You can configure a maximum of 200 index fields.
  ## 
  let valid = call_601097.validator(path, query, header, formData, body)
  let scheme = call_601097.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601097.url(scheme.get, call_601097.host, call_601097.base,
                         call_601097.route, valid.getOrDefault("path"))
  result = hook(call_601097, url, valid)

proc call*(call_601098: Call_PostDefineIndexField_601078; DomainName: string;
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
  var query_601099 = newJObject()
  var formData_601100 = newJObject()
  add(formData_601100, "IndexField.UIntOptions", newJString(IndexFieldUIntOptions))
  add(formData_601100, "IndexField.TextOptions", newJString(IndexFieldTextOptions))
  add(formData_601100, "DomainName", newJString(DomainName))
  add(formData_601100, "IndexField.LiteralOptions",
      newJString(IndexFieldLiteralOptions))
  add(formData_601100, "IndexField.IndexFieldType",
      newJString(IndexFieldIndexFieldType))
  add(query_601099, "Action", newJString(Action))
  add(formData_601100, "IndexField.IndexFieldName",
      newJString(IndexFieldIndexFieldName))
  add(query_601099, "Version", newJString(Version))
  if IndexFieldSourceAttributes != nil:
    formData_601100.add "IndexField.SourceAttributes", IndexFieldSourceAttributes
  result = call_601098.call(nil, query_601099, nil, formData_601100, nil)

var postDefineIndexField* = Call_PostDefineIndexField_601078(
    name: "postDefineIndexField", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineIndexField",
    validator: validate_PostDefineIndexField_601079, base: "/",
    url: url_PostDefineIndexField_601080, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDefineIndexField_601056 = ref object of OpenApiRestCall_600426
proc url_GetDefineIndexField_601058(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDefineIndexField_601057(path: JsonNode; query: JsonNode;
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
  var valid_601059 = query.getOrDefault("IndexField.TextOptions")
  valid_601059 = validateParameter(valid_601059, JString, required = false,
                                 default = nil)
  if valid_601059 != nil:
    section.add "IndexField.TextOptions", valid_601059
  var valid_601060 = query.getOrDefault("IndexField.LiteralOptions")
  valid_601060 = validateParameter(valid_601060, JString, required = false,
                                 default = nil)
  if valid_601060 != nil:
    section.add "IndexField.LiteralOptions", valid_601060
  var valid_601061 = query.getOrDefault("IndexField.UIntOptions")
  valid_601061 = validateParameter(valid_601061, JString, required = false,
                                 default = nil)
  if valid_601061 != nil:
    section.add "IndexField.UIntOptions", valid_601061
  var valid_601062 = query.getOrDefault("IndexField.IndexFieldType")
  valid_601062 = validateParameter(valid_601062, JString, required = false,
                                 default = nil)
  if valid_601062 != nil:
    section.add "IndexField.IndexFieldType", valid_601062
  var valid_601063 = query.getOrDefault("IndexField.SourceAttributes")
  valid_601063 = validateParameter(valid_601063, JArray, required = false,
                                 default = nil)
  if valid_601063 != nil:
    section.add "IndexField.SourceAttributes", valid_601063
  var valid_601064 = query.getOrDefault("IndexField.IndexFieldName")
  valid_601064 = validateParameter(valid_601064, JString, required = false,
                                 default = nil)
  if valid_601064 != nil:
    section.add "IndexField.IndexFieldName", valid_601064
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601065 = query.getOrDefault("Action")
  valid_601065 = validateParameter(valid_601065, JString, required = true,
                                 default = newJString("DefineIndexField"))
  if valid_601065 != nil:
    section.add "Action", valid_601065
  var valid_601066 = query.getOrDefault("DomainName")
  valid_601066 = validateParameter(valid_601066, JString, required = true,
                                 default = nil)
  if valid_601066 != nil:
    section.add "DomainName", valid_601066
  var valid_601067 = query.getOrDefault("Version")
  valid_601067 = validateParameter(valid_601067, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_601067 != nil:
    section.add "Version", valid_601067
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
  var valid_601068 = header.getOrDefault("X-Amz-Date")
  valid_601068 = validateParameter(valid_601068, JString, required = false,
                                 default = nil)
  if valid_601068 != nil:
    section.add "X-Amz-Date", valid_601068
  var valid_601069 = header.getOrDefault("X-Amz-Security-Token")
  valid_601069 = validateParameter(valid_601069, JString, required = false,
                                 default = nil)
  if valid_601069 != nil:
    section.add "X-Amz-Security-Token", valid_601069
  var valid_601070 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601070 = validateParameter(valid_601070, JString, required = false,
                                 default = nil)
  if valid_601070 != nil:
    section.add "X-Amz-Content-Sha256", valid_601070
  var valid_601071 = header.getOrDefault("X-Amz-Algorithm")
  valid_601071 = validateParameter(valid_601071, JString, required = false,
                                 default = nil)
  if valid_601071 != nil:
    section.add "X-Amz-Algorithm", valid_601071
  var valid_601072 = header.getOrDefault("X-Amz-Signature")
  valid_601072 = validateParameter(valid_601072, JString, required = false,
                                 default = nil)
  if valid_601072 != nil:
    section.add "X-Amz-Signature", valid_601072
  var valid_601073 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601073 = validateParameter(valid_601073, JString, required = false,
                                 default = nil)
  if valid_601073 != nil:
    section.add "X-Amz-SignedHeaders", valid_601073
  var valid_601074 = header.getOrDefault("X-Amz-Credential")
  valid_601074 = validateParameter(valid_601074, JString, required = false,
                                 default = nil)
  if valid_601074 != nil:
    section.add "X-Amz-Credential", valid_601074
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601075: Call_GetDefineIndexField_601056; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures an <code>IndexField</code> for the search domain. Used to create new fields and modify existing ones. If the field exists, the new configuration replaces the old one. You can configure a maximum of 200 index fields.
  ## 
  let valid = call_601075.validator(path, query, header, formData, body)
  let scheme = call_601075.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601075.url(scheme.get, call_601075.host, call_601075.base,
                         call_601075.route, valid.getOrDefault("path"))
  result = hook(call_601075, url, valid)

proc call*(call_601076: Call_GetDefineIndexField_601056; DomainName: string;
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
  var query_601077 = newJObject()
  add(query_601077, "IndexField.TextOptions", newJString(IndexFieldTextOptions))
  add(query_601077, "IndexField.LiteralOptions",
      newJString(IndexFieldLiteralOptions))
  add(query_601077, "IndexField.UIntOptions", newJString(IndexFieldUIntOptions))
  add(query_601077, "IndexField.IndexFieldType",
      newJString(IndexFieldIndexFieldType))
  if IndexFieldSourceAttributes != nil:
    query_601077.add "IndexField.SourceAttributes", IndexFieldSourceAttributes
  add(query_601077, "IndexField.IndexFieldName",
      newJString(IndexFieldIndexFieldName))
  add(query_601077, "Action", newJString(Action))
  add(query_601077, "DomainName", newJString(DomainName))
  add(query_601077, "Version", newJString(Version))
  result = call_601076.call(nil, query_601077, nil, nil, nil)

var getDefineIndexField* = Call_GetDefineIndexField_601056(
    name: "getDefineIndexField", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineIndexField",
    validator: validate_GetDefineIndexField_601057, base: "/",
    url: url_GetDefineIndexField_601058, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDefineRankExpression_601119 = ref object of OpenApiRestCall_600426
proc url_PostDefineRankExpression_601121(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDefineRankExpression_601120(path: JsonNode; query: JsonNode;
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
  var valid_601122 = query.getOrDefault("Action")
  valid_601122 = validateParameter(valid_601122, JString, required = true,
                                 default = newJString("DefineRankExpression"))
  if valid_601122 != nil:
    section.add "Action", valid_601122
  var valid_601123 = query.getOrDefault("Version")
  valid_601123 = validateParameter(valid_601123, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_601123 != nil:
    section.add "Version", valid_601123
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
  var valid_601124 = header.getOrDefault("X-Amz-Date")
  valid_601124 = validateParameter(valid_601124, JString, required = false,
                                 default = nil)
  if valid_601124 != nil:
    section.add "X-Amz-Date", valid_601124
  var valid_601125 = header.getOrDefault("X-Amz-Security-Token")
  valid_601125 = validateParameter(valid_601125, JString, required = false,
                                 default = nil)
  if valid_601125 != nil:
    section.add "X-Amz-Security-Token", valid_601125
  var valid_601126 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601126 = validateParameter(valid_601126, JString, required = false,
                                 default = nil)
  if valid_601126 != nil:
    section.add "X-Amz-Content-Sha256", valid_601126
  var valid_601127 = header.getOrDefault("X-Amz-Algorithm")
  valid_601127 = validateParameter(valid_601127, JString, required = false,
                                 default = nil)
  if valid_601127 != nil:
    section.add "X-Amz-Algorithm", valid_601127
  var valid_601128 = header.getOrDefault("X-Amz-Signature")
  valid_601128 = validateParameter(valid_601128, JString, required = false,
                                 default = nil)
  if valid_601128 != nil:
    section.add "X-Amz-Signature", valid_601128
  var valid_601129 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601129 = validateParameter(valid_601129, JString, required = false,
                                 default = nil)
  if valid_601129 != nil:
    section.add "X-Amz-SignedHeaders", valid_601129
  var valid_601130 = header.getOrDefault("X-Amz-Credential")
  valid_601130 = validateParameter(valid_601130, JString, required = false,
                                 default = nil)
  if valid_601130 != nil:
    section.add "X-Amz-Credential", valid_601130
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
  var valid_601131 = formData.getOrDefault("DomainName")
  valid_601131 = validateParameter(valid_601131, JString, required = true,
                                 default = nil)
  if valid_601131 != nil:
    section.add "DomainName", valid_601131
  var valid_601132 = formData.getOrDefault("RankExpression.RankName")
  valid_601132 = validateParameter(valid_601132, JString, required = false,
                                 default = nil)
  if valid_601132 != nil:
    section.add "RankExpression.RankName", valid_601132
  var valid_601133 = formData.getOrDefault("RankExpression.RankExpression")
  valid_601133 = validateParameter(valid_601133, JString, required = false,
                                 default = nil)
  if valid_601133 != nil:
    section.add "RankExpression.RankExpression", valid_601133
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601134: Call_PostDefineRankExpression_601119; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a <code>RankExpression</code> for the search domain. Used to create new rank expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. You can configure a maximum of 50 rank expressions.
  ## 
  let valid = call_601134.validator(path, query, header, formData, body)
  let scheme = call_601134.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601134.url(scheme.get, call_601134.host, call_601134.base,
                         call_601134.route, valid.getOrDefault("path"))
  result = hook(call_601134, url, valid)

proc call*(call_601135: Call_PostDefineRankExpression_601119; DomainName: string;
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
  var query_601136 = newJObject()
  var formData_601137 = newJObject()
  add(formData_601137, "DomainName", newJString(DomainName))
  add(formData_601137, "RankExpression.RankName",
      newJString(RankExpressionRankName))
  add(formData_601137, "RankExpression.RankExpression",
      newJString(RankExpressionRankExpression))
  add(query_601136, "Action", newJString(Action))
  add(query_601136, "Version", newJString(Version))
  result = call_601135.call(nil, query_601136, nil, formData_601137, nil)

var postDefineRankExpression* = Call_PostDefineRankExpression_601119(
    name: "postDefineRankExpression", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineRankExpression",
    validator: validate_PostDefineRankExpression_601120, base: "/",
    url: url_PostDefineRankExpression_601121, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDefineRankExpression_601101 = ref object of OpenApiRestCall_600426
proc url_GetDefineRankExpression_601103(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDefineRankExpression_601102(path: JsonNode; query: JsonNode;
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
  var valid_601104 = query.getOrDefault("Action")
  valid_601104 = validateParameter(valid_601104, JString, required = true,
                                 default = newJString("DefineRankExpression"))
  if valid_601104 != nil:
    section.add "Action", valid_601104
  var valid_601105 = query.getOrDefault("RankExpression.RankExpression")
  valid_601105 = validateParameter(valid_601105, JString, required = false,
                                 default = nil)
  if valid_601105 != nil:
    section.add "RankExpression.RankExpression", valid_601105
  var valid_601106 = query.getOrDefault("RankExpression.RankName")
  valid_601106 = validateParameter(valid_601106, JString, required = false,
                                 default = nil)
  if valid_601106 != nil:
    section.add "RankExpression.RankName", valid_601106
  var valid_601107 = query.getOrDefault("DomainName")
  valid_601107 = validateParameter(valid_601107, JString, required = true,
                                 default = nil)
  if valid_601107 != nil:
    section.add "DomainName", valid_601107
  var valid_601108 = query.getOrDefault("Version")
  valid_601108 = validateParameter(valid_601108, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_601108 != nil:
    section.add "Version", valid_601108
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
  var valid_601109 = header.getOrDefault("X-Amz-Date")
  valid_601109 = validateParameter(valid_601109, JString, required = false,
                                 default = nil)
  if valid_601109 != nil:
    section.add "X-Amz-Date", valid_601109
  var valid_601110 = header.getOrDefault("X-Amz-Security-Token")
  valid_601110 = validateParameter(valid_601110, JString, required = false,
                                 default = nil)
  if valid_601110 != nil:
    section.add "X-Amz-Security-Token", valid_601110
  var valid_601111 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601111 = validateParameter(valid_601111, JString, required = false,
                                 default = nil)
  if valid_601111 != nil:
    section.add "X-Amz-Content-Sha256", valid_601111
  var valid_601112 = header.getOrDefault("X-Amz-Algorithm")
  valid_601112 = validateParameter(valid_601112, JString, required = false,
                                 default = nil)
  if valid_601112 != nil:
    section.add "X-Amz-Algorithm", valid_601112
  var valid_601113 = header.getOrDefault("X-Amz-Signature")
  valid_601113 = validateParameter(valid_601113, JString, required = false,
                                 default = nil)
  if valid_601113 != nil:
    section.add "X-Amz-Signature", valid_601113
  var valid_601114 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601114 = validateParameter(valid_601114, JString, required = false,
                                 default = nil)
  if valid_601114 != nil:
    section.add "X-Amz-SignedHeaders", valid_601114
  var valid_601115 = header.getOrDefault("X-Amz-Credential")
  valid_601115 = validateParameter(valid_601115, JString, required = false,
                                 default = nil)
  if valid_601115 != nil:
    section.add "X-Amz-Credential", valid_601115
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601116: Call_GetDefineRankExpression_601101; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a <code>RankExpression</code> for the search domain. Used to create new rank expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. You can configure a maximum of 50 rank expressions.
  ## 
  let valid = call_601116.validator(path, query, header, formData, body)
  let scheme = call_601116.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601116.url(scheme.get, call_601116.host, call_601116.base,
                         call_601116.route, valid.getOrDefault("path"))
  result = hook(call_601116, url, valid)

proc call*(call_601117: Call_GetDefineRankExpression_601101; DomainName: string;
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
  var query_601118 = newJObject()
  add(query_601118, "Action", newJString(Action))
  add(query_601118, "RankExpression.RankExpression",
      newJString(RankExpressionRankExpression))
  add(query_601118, "RankExpression.RankName", newJString(RankExpressionRankName))
  add(query_601118, "DomainName", newJString(DomainName))
  add(query_601118, "Version", newJString(Version))
  result = call_601117.call(nil, query_601118, nil, nil, nil)

var getDefineRankExpression* = Call_GetDefineRankExpression_601101(
    name: "getDefineRankExpression", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineRankExpression",
    validator: validate_GetDefineRankExpression_601102, base: "/",
    url: url_GetDefineRankExpression_601103, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDomain_601154 = ref object of OpenApiRestCall_600426
proc url_PostDeleteDomain_601156(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteDomain_601155(path: JsonNode; query: JsonNode;
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
  var valid_601157 = query.getOrDefault("Action")
  valid_601157 = validateParameter(valid_601157, JString, required = true,
                                 default = newJString("DeleteDomain"))
  if valid_601157 != nil:
    section.add "Action", valid_601157
  var valid_601158 = query.getOrDefault("Version")
  valid_601158 = validateParameter(valid_601158, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_601158 != nil:
    section.add "Version", valid_601158
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
  var valid_601159 = header.getOrDefault("X-Amz-Date")
  valid_601159 = validateParameter(valid_601159, JString, required = false,
                                 default = nil)
  if valid_601159 != nil:
    section.add "X-Amz-Date", valid_601159
  var valid_601160 = header.getOrDefault("X-Amz-Security-Token")
  valid_601160 = validateParameter(valid_601160, JString, required = false,
                                 default = nil)
  if valid_601160 != nil:
    section.add "X-Amz-Security-Token", valid_601160
  var valid_601161 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601161 = validateParameter(valid_601161, JString, required = false,
                                 default = nil)
  if valid_601161 != nil:
    section.add "X-Amz-Content-Sha256", valid_601161
  var valid_601162 = header.getOrDefault("X-Amz-Algorithm")
  valid_601162 = validateParameter(valid_601162, JString, required = false,
                                 default = nil)
  if valid_601162 != nil:
    section.add "X-Amz-Algorithm", valid_601162
  var valid_601163 = header.getOrDefault("X-Amz-Signature")
  valid_601163 = validateParameter(valid_601163, JString, required = false,
                                 default = nil)
  if valid_601163 != nil:
    section.add "X-Amz-Signature", valid_601163
  var valid_601164 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601164 = validateParameter(valid_601164, JString, required = false,
                                 default = nil)
  if valid_601164 != nil:
    section.add "X-Amz-SignedHeaders", valid_601164
  var valid_601165 = header.getOrDefault("X-Amz-Credential")
  valid_601165 = validateParameter(valid_601165, JString, required = false,
                                 default = nil)
  if valid_601165 != nil:
    section.add "X-Amz-Credential", valid_601165
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_601166 = formData.getOrDefault("DomainName")
  valid_601166 = validateParameter(valid_601166, JString, required = true,
                                 default = nil)
  if valid_601166 != nil:
    section.add "DomainName", valid_601166
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601167: Call_PostDeleteDomain_601154; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently deletes a search domain and all of its data.
  ## 
  let valid = call_601167.validator(path, query, header, formData, body)
  let scheme = call_601167.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601167.url(scheme.get, call_601167.host, call_601167.base,
                         call_601167.route, valid.getOrDefault("path"))
  result = hook(call_601167, url, valid)

proc call*(call_601168: Call_PostDeleteDomain_601154; DomainName: string;
          Action: string = "DeleteDomain"; Version: string = "2011-02-01"): Recallable =
  ## postDeleteDomain
  ## Permanently deletes a search domain and all of its data.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601169 = newJObject()
  var formData_601170 = newJObject()
  add(formData_601170, "DomainName", newJString(DomainName))
  add(query_601169, "Action", newJString(Action))
  add(query_601169, "Version", newJString(Version))
  result = call_601168.call(nil, query_601169, nil, formData_601170, nil)

var postDeleteDomain* = Call_PostDeleteDomain_601154(name: "postDeleteDomain",
    meth: HttpMethod.HttpPost, host: "cloudsearch.amazonaws.com",
    route: "/#Action=DeleteDomain", validator: validate_PostDeleteDomain_601155,
    base: "/", url: url_PostDeleteDomain_601156,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDomain_601138 = ref object of OpenApiRestCall_600426
proc url_GetDeleteDomain_601140(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteDomain_601139(path: JsonNode; query: JsonNode;
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
  var valid_601141 = query.getOrDefault("Action")
  valid_601141 = validateParameter(valid_601141, JString, required = true,
                                 default = newJString("DeleteDomain"))
  if valid_601141 != nil:
    section.add "Action", valid_601141
  var valid_601142 = query.getOrDefault("DomainName")
  valid_601142 = validateParameter(valid_601142, JString, required = true,
                                 default = nil)
  if valid_601142 != nil:
    section.add "DomainName", valid_601142
  var valid_601143 = query.getOrDefault("Version")
  valid_601143 = validateParameter(valid_601143, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_601143 != nil:
    section.add "Version", valid_601143
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
  var valid_601144 = header.getOrDefault("X-Amz-Date")
  valid_601144 = validateParameter(valid_601144, JString, required = false,
                                 default = nil)
  if valid_601144 != nil:
    section.add "X-Amz-Date", valid_601144
  var valid_601145 = header.getOrDefault("X-Amz-Security-Token")
  valid_601145 = validateParameter(valid_601145, JString, required = false,
                                 default = nil)
  if valid_601145 != nil:
    section.add "X-Amz-Security-Token", valid_601145
  var valid_601146 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601146 = validateParameter(valid_601146, JString, required = false,
                                 default = nil)
  if valid_601146 != nil:
    section.add "X-Amz-Content-Sha256", valid_601146
  var valid_601147 = header.getOrDefault("X-Amz-Algorithm")
  valid_601147 = validateParameter(valid_601147, JString, required = false,
                                 default = nil)
  if valid_601147 != nil:
    section.add "X-Amz-Algorithm", valid_601147
  var valid_601148 = header.getOrDefault("X-Amz-Signature")
  valid_601148 = validateParameter(valid_601148, JString, required = false,
                                 default = nil)
  if valid_601148 != nil:
    section.add "X-Amz-Signature", valid_601148
  var valid_601149 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601149 = validateParameter(valid_601149, JString, required = false,
                                 default = nil)
  if valid_601149 != nil:
    section.add "X-Amz-SignedHeaders", valid_601149
  var valid_601150 = header.getOrDefault("X-Amz-Credential")
  valid_601150 = validateParameter(valid_601150, JString, required = false,
                                 default = nil)
  if valid_601150 != nil:
    section.add "X-Amz-Credential", valid_601150
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601151: Call_GetDeleteDomain_601138; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently deletes a search domain and all of its data.
  ## 
  let valid = call_601151.validator(path, query, header, formData, body)
  let scheme = call_601151.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601151.url(scheme.get, call_601151.host, call_601151.base,
                         call_601151.route, valid.getOrDefault("path"))
  result = hook(call_601151, url, valid)

proc call*(call_601152: Call_GetDeleteDomain_601138; DomainName: string;
          Action: string = "DeleteDomain"; Version: string = "2011-02-01"): Recallable =
  ## getDeleteDomain
  ## Permanently deletes a search domain and all of its data.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_601153 = newJObject()
  add(query_601153, "Action", newJString(Action))
  add(query_601153, "DomainName", newJString(DomainName))
  add(query_601153, "Version", newJString(Version))
  result = call_601152.call(nil, query_601153, nil, nil, nil)

var getDeleteDomain* = Call_GetDeleteDomain_601138(name: "getDeleteDomain",
    meth: HttpMethod.HttpGet, host: "cloudsearch.amazonaws.com",
    route: "/#Action=DeleteDomain", validator: validate_GetDeleteDomain_601139,
    base: "/", url: url_GetDeleteDomain_601140, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteIndexField_601188 = ref object of OpenApiRestCall_600426
proc url_PostDeleteIndexField_601190(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteIndexField_601189(path: JsonNode; query: JsonNode;
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
  var valid_601191 = query.getOrDefault("Action")
  valid_601191 = validateParameter(valid_601191, JString, required = true,
                                 default = newJString("DeleteIndexField"))
  if valid_601191 != nil:
    section.add "Action", valid_601191
  var valid_601192 = query.getOrDefault("Version")
  valid_601192 = validateParameter(valid_601192, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_601192 != nil:
    section.add "Version", valid_601192
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
  var valid_601193 = header.getOrDefault("X-Amz-Date")
  valid_601193 = validateParameter(valid_601193, JString, required = false,
                                 default = nil)
  if valid_601193 != nil:
    section.add "X-Amz-Date", valid_601193
  var valid_601194 = header.getOrDefault("X-Amz-Security-Token")
  valid_601194 = validateParameter(valid_601194, JString, required = false,
                                 default = nil)
  if valid_601194 != nil:
    section.add "X-Amz-Security-Token", valid_601194
  var valid_601195 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601195 = validateParameter(valid_601195, JString, required = false,
                                 default = nil)
  if valid_601195 != nil:
    section.add "X-Amz-Content-Sha256", valid_601195
  var valid_601196 = header.getOrDefault("X-Amz-Algorithm")
  valid_601196 = validateParameter(valid_601196, JString, required = false,
                                 default = nil)
  if valid_601196 != nil:
    section.add "X-Amz-Algorithm", valid_601196
  var valid_601197 = header.getOrDefault("X-Amz-Signature")
  valid_601197 = validateParameter(valid_601197, JString, required = false,
                                 default = nil)
  if valid_601197 != nil:
    section.add "X-Amz-Signature", valid_601197
  var valid_601198 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601198 = validateParameter(valid_601198, JString, required = false,
                                 default = nil)
  if valid_601198 != nil:
    section.add "X-Amz-SignedHeaders", valid_601198
  var valid_601199 = header.getOrDefault("X-Amz-Credential")
  valid_601199 = validateParameter(valid_601199, JString, required = false,
                                 default = nil)
  if valid_601199 != nil:
    section.add "X-Amz-Credential", valid_601199
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   IndexFieldName: JString (required)
  ##                 : A string that represents the name of an index field. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_601200 = formData.getOrDefault("DomainName")
  valid_601200 = validateParameter(valid_601200, JString, required = true,
                                 default = nil)
  if valid_601200 != nil:
    section.add "DomainName", valid_601200
  var valid_601201 = formData.getOrDefault("IndexFieldName")
  valid_601201 = validateParameter(valid_601201, JString, required = true,
                                 default = nil)
  if valid_601201 != nil:
    section.add "IndexFieldName", valid_601201
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601202: Call_PostDeleteIndexField_601188; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes an <code>IndexField</code> from the search domain.
  ## 
  let valid = call_601202.validator(path, query, header, formData, body)
  let scheme = call_601202.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601202.url(scheme.get, call_601202.host, call_601202.base,
                         call_601202.route, valid.getOrDefault("path"))
  result = hook(call_601202, url, valid)

proc call*(call_601203: Call_PostDeleteIndexField_601188; DomainName: string;
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
  var query_601204 = newJObject()
  var formData_601205 = newJObject()
  add(formData_601205, "DomainName", newJString(DomainName))
  add(formData_601205, "IndexFieldName", newJString(IndexFieldName))
  add(query_601204, "Action", newJString(Action))
  add(query_601204, "Version", newJString(Version))
  result = call_601203.call(nil, query_601204, nil, formData_601205, nil)

var postDeleteIndexField* = Call_PostDeleteIndexField_601188(
    name: "postDeleteIndexField", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteIndexField",
    validator: validate_PostDeleteIndexField_601189, base: "/",
    url: url_PostDeleteIndexField_601190, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteIndexField_601171 = ref object of OpenApiRestCall_600426
proc url_GetDeleteIndexField_601173(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteIndexField_601172(path: JsonNode; query: JsonNode;
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
  var valid_601174 = query.getOrDefault("IndexFieldName")
  valid_601174 = validateParameter(valid_601174, JString, required = true,
                                 default = nil)
  if valid_601174 != nil:
    section.add "IndexFieldName", valid_601174
  var valid_601175 = query.getOrDefault("Action")
  valid_601175 = validateParameter(valid_601175, JString, required = true,
                                 default = newJString("DeleteIndexField"))
  if valid_601175 != nil:
    section.add "Action", valid_601175
  var valid_601176 = query.getOrDefault("DomainName")
  valid_601176 = validateParameter(valid_601176, JString, required = true,
                                 default = nil)
  if valid_601176 != nil:
    section.add "DomainName", valid_601176
  var valid_601177 = query.getOrDefault("Version")
  valid_601177 = validateParameter(valid_601177, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_601177 != nil:
    section.add "Version", valid_601177
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
  var valid_601178 = header.getOrDefault("X-Amz-Date")
  valid_601178 = validateParameter(valid_601178, JString, required = false,
                                 default = nil)
  if valid_601178 != nil:
    section.add "X-Amz-Date", valid_601178
  var valid_601179 = header.getOrDefault("X-Amz-Security-Token")
  valid_601179 = validateParameter(valid_601179, JString, required = false,
                                 default = nil)
  if valid_601179 != nil:
    section.add "X-Amz-Security-Token", valid_601179
  var valid_601180 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601180 = validateParameter(valid_601180, JString, required = false,
                                 default = nil)
  if valid_601180 != nil:
    section.add "X-Amz-Content-Sha256", valid_601180
  var valid_601181 = header.getOrDefault("X-Amz-Algorithm")
  valid_601181 = validateParameter(valid_601181, JString, required = false,
                                 default = nil)
  if valid_601181 != nil:
    section.add "X-Amz-Algorithm", valid_601181
  var valid_601182 = header.getOrDefault("X-Amz-Signature")
  valid_601182 = validateParameter(valid_601182, JString, required = false,
                                 default = nil)
  if valid_601182 != nil:
    section.add "X-Amz-Signature", valid_601182
  var valid_601183 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601183 = validateParameter(valid_601183, JString, required = false,
                                 default = nil)
  if valid_601183 != nil:
    section.add "X-Amz-SignedHeaders", valid_601183
  var valid_601184 = header.getOrDefault("X-Amz-Credential")
  valid_601184 = validateParameter(valid_601184, JString, required = false,
                                 default = nil)
  if valid_601184 != nil:
    section.add "X-Amz-Credential", valid_601184
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601185: Call_GetDeleteIndexField_601171; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes an <code>IndexField</code> from the search domain.
  ## 
  let valid = call_601185.validator(path, query, header, formData, body)
  let scheme = call_601185.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601185.url(scheme.get, call_601185.host, call_601185.base,
                         call_601185.route, valid.getOrDefault("path"))
  result = hook(call_601185, url, valid)

proc call*(call_601186: Call_GetDeleteIndexField_601171; IndexFieldName: string;
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
  var query_601187 = newJObject()
  add(query_601187, "IndexFieldName", newJString(IndexFieldName))
  add(query_601187, "Action", newJString(Action))
  add(query_601187, "DomainName", newJString(DomainName))
  add(query_601187, "Version", newJString(Version))
  result = call_601186.call(nil, query_601187, nil, nil, nil)

var getDeleteIndexField* = Call_GetDeleteIndexField_601171(
    name: "getDeleteIndexField", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteIndexField",
    validator: validate_GetDeleteIndexField_601172, base: "/",
    url: url_GetDeleteIndexField_601173, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteRankExpression_601223 = ref object of OpenApiRestCall_600426
proc url_PostDeleteRankExpression_601225(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDeleteRankExpression_601224(path: JsonNode; query: JsonNode;
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
  var valid_601226 = query.getOrDefault("Action")
  valid_601226 = validateParameter(valid_601226, JString, required = true,
                                 default = newJString("DeleteRankExpression"))
  if valid_601226 != nil:
    section.add "Action", valid_601226
  var valid_601227 = query.getOrDefault("Version")
  valid_601227 = validateParameter(valid_601227, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_601227 != nil:
    section.add "Version", valid_601227
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
  var valid_601228 = header.getOrDefault("X-Amz-Date")
  valid_601228 = validateParameter(valid_601228, JString, required = false,
                                 default = nil)
  if valid_601228 != nil:
    section.add "X-Amz-Date", valid_601228
  var valid_601229 = header.getOrDefault("X-Amz-Security-Token")
  valid_601229 = validateParameter(valid_601229, JString, required = false,
                                 default = nil)
  if valid_601229 != nil:
    section.add "X-Amz-Security-Token", valid_601229
  var valid_601230 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601230 = validateParameter(valid_601230, JString, required = false,
                                 default = nil)
  if valid_601230 != nil:
    section.add "X-Amz-Content-Sha256", valid_601230
  var valid_601231 = header.getOrDefault("X-Amz-Algorithm")
  valid_601231 = validateParameter(valid_601231, JString, required = false,
                                 default = nil)
  if valid_601231 != nil:
    section.add "X-Amz-Algorithm", valid_601231
  var valid_601232 = header.getOrDefault("X-Amz-Signature")
  valid_601232 = validateParameter(valid_601232, JString, required = false,
                                 default = nil)
  if valid_601232 != nil:
    section.add "X-Amz-Signature", valid_601232
  var valid_601233 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601233 = validateParameter(valid_601233, JString, required = false,
                                 default = nil)
  if valid_601233 != nil:
    section.add "X-Amz-SignedHeaders", valid_601233
  var valid_601234 = header.getOrDefault("X-Amz-Credential")
  valid_601234 = validateParameter(valid_601234, JString, required = false,
                                 default = nil)
  if valid_601234 != nil:
    section.add "X-Amz-Credential", valid_601234
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   RankName: JString (required)
  ##           : A string that represents the name of an index field. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_601235 = formData.getOrDefault("DomainName")
  valid_601235 = validateParameter(valid_601235, JString, required = true,
                                 default = nil)
  if valid_601235 != nil:
    section.add "DomainName", valid_601235
  var valid_601236 = formData.getOrDefault("RankName")
  valid_601236 = validateParameter(valid_601236, JString, required = true,
                                 default = nil)
  if valid_601236 != nil:
    section.add "RankName", valid_601236
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601237: Call_PostDeleteRankExpression_601223; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a <code>RankExpression</code> from the search domain.
  ## 
  let valid = call_601237.validator(path, query, header, formData, body)
  let scheme = call_601237.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601237.url(scheme.get, call_601237.host, call_601237.base,
                         call_601237.route, valid.getOrDefault("path"))
  result = hook(call_601237, url, valid)

proc call*(call_601238: Call_PostDeleteRankExpression_601223; DomainName: string;
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
  var query_601239 = newJObject()
  var formData_601240 = newJObject()
  add(formData_601240, "DomainName", newJString(DomainName))
  add(query_601239, "Action", newJString(Action))
  add(formData_601240, "RankName", newJString(RankName))
  add(query_601239, "Version", newJString(Version))
  result = call_601238.call(nil, query_601239, nil, formData_601240, nil)

var postDeleteRankExpression* = Call_PostDeleteRankExpression_601223(
    name: "postDeleteRankExpression", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteRankExpression",
    validator: validate_PostDeleteRankExpression_601224, base: "/",
    url: url_PostDeleteRankExpression_601225, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteRankExpression_601206 = ref object of OpenApiRestCall_600426
proc url_GetDeleteRankExpression_601208(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDeleteRankExpression_601207(path: JsonNode; query: JsonNode;
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
  var valid_601209 = query.getOrDefault("RankName")
  valid_601209 = validateParameter(valid_601209, JString, required = true,
                                 default = nil)
  if valid_601209 != nil:
    section.add "RankName", valid_601209
  var valid_601210 = query.getOrDefault("Action")
  valid_601210 = validateParameter(valid_601210, JString, required = true,
                                 default = newJString("DeleteRankExpression"))
  if valid_601210 != nil:
    section.add "Action", valid_601210
  var valid_601211 = query.getOrDefault("DomainName")
  valid_601211 = validateParameter(valid_601211, JString, required = true,
                                 default = nil)
  if valid_601211 != nil:
    section.add "DomainName", valid_601211
  var valid_601212 = query.getOrDefault("Version")
  valid_601212 = validateParameter(valid_601212, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_601212 != nil:
    section.add "Version", valid_601212
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
  var valid_601213 = header.getOrDefault("X-Amz-Date")
  valid_601213 = validateParameter(valid_601213, JString, required = false,
                                 default = nil)
  if valid_601213 != nil:
    section.add "X-Amz-Date", valid_601213
  var valid_601214 = header.getOrDefault("X-Amz-Security-Token")
  valid_601214 = validateParameter(valid_601214, JString, required = false,
                                 default = nil)
  if valid_601214 != nil:
    section.add "X-Amz-Security-Token", valid_601214
  var valid_601215 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601215 = validateParameter(valid_601215, JString, required = false,
                                 default = nil)
  if valid_601215 != nil:
    section.add "X-Amz-Content-Sha256", valid_601215
  var valid_601216 = header.getOrDefault("X-Amz-Algorithm")
  valid_601216 = validateParameter(valid_601216, JString, required = false,
                                 default = nil)
  if valid_601216 != nil:
    section.add "X-Amz-Algorithm", valid_601216
  var valid_601217 = header.getOrDefault("X-Amz-Signature")
  valid_601217 = validateParameter(valid_601217, JString, required = false,
                                 default = nil)
  if valid_601217 != nil:
    section.add "X-Amz-Signature", valid_601217
  var valid_601218 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601218 = validateParameter(valid_601218, JString, required = false,
                                 default = nil)
  if valid_601218 != nil:
    section.add "X-Amz-SignedHeaders", valid_601218
  var valid_601219 = header.getOrDefault("X-Amz-Credential")
  valid_601219 = validateParameter(valid_601219, JString, required = false,
                                 default = nil)
  if valid_601219 != nil:
    section.add "X-Amz-Credential", valid_601219
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601220: Call_GetDeleteRankExpression_601206; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a <code>RankExpression</code> from the search domain.
  ## 
  let valid = call_601220.validator(path, query, header, formData, body)
  let scheme = call_601220.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601220.url(scheme.get, call_601220.host, call_601220.base,
                         call_601220.route, valid.getOrDefault("path"))
  result = hook(call_601220, url, valid)

proc call*(call_601221: Call_GetDeleteRankExpression_601206; RankName: string;
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
  var query_601222 = newJObject()
  add(query_601222, "RankName", newJString(RankName))
  add(query_601222, "Action", newJString(Action))
  add(query_601222, "DomainName", newJString(DomainName))
  add(query_601222, "Version", newJString(Version))
  result = call_601221.call(nil, query_601222, nil, nil, nil)

var getDeleteRankExpression* = Call_GetDeleteRankExpression_601206(
    name: "getDeleteRankExpression", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteRankExpression",
    validator: validate_GetDeleteRankExpression_601207, base: "/",
    url: url_GetDeleteRankExpression_601208, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAvailabilityOptions_601257 = ref object of OpenApiRestCall_600426
proc url_PostDescribeAvailabilityOptions_601259(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeAvailabilityOptions_601258(path: JsonNode;
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
  var valid_601260 = query.getOrDefault("Action")
  valid_601260 = validateParameter(valid_601260, JString, required = true, default = newJString(
      "DescribeAvailabilityOptions"))
  if valid_601260 != nil:
    section.add "Action", valid_601260
  var valid_601261 = query.getOrDefault("Version")
  valid_601261 = validateParameter(valid_601261, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_601261 != nil:
    section.add "Version", valid_601261
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
  var valid_601262 = header.getOrDefault("X-Amz-Date")
  valid_601262 = validateParameter(valid_601262, JString, required = false,
                                 default = nil)
  if valid_601262 != nil:
    section.add "X-Amz-Date", valid_601262
  var valid_601263 = header.getOrDefault("X-Amz-Security-Token")
  valid_601263 = validateParameter(valid_601263, JString, required = false,
                                 default = nil)
  if valid_601263 != nil:
    section.add "X-Amz-Security-Token", valid_601263
  var valid_601264 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601264 = validateParameter(valid_601264, JString, required = false,
                                 default = nil)
  if valid_601264 != nil:
    section.add "X-Amz-Content-Sha256", valid_601264
  var valid_601265 = header.getOrDefault("X-Amz-Algorithm")
  valid_601265 = validateParameter(valid_601265, JString, required = false,
                                 default = nil)
  if valid_601265 != nil:
    section.add "X-Amz-Algorithm", valid_601265
  var valid_601266 = header.getOrDefault("X-Amz-Signature")
  valid_601266 = validateParameter(valid_601266, JString, required = false,
                                 default = nil)
  if valid_601266 != nil:
    section.add "X-Amz-Signature", valid_601266
  var valid_601267 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601267 = validateParameter(valid_601267, JString, required = false,
                                 default = nil)
  if valid_601267 != nil:
    section.add "X-Amz-SignedHeaders", valid_601267
  var valid_601268 = header.getOrDefault("X-Amz-Credential")
  valid_601268 = validateParameter(valid_601268, JString, required = false,
                                 default = nil)
  if valid_601268 != nil:
    section.add "X-Amz-Credential", valid_601268
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_601269 = formData.getOrDefault("DomainName")
  valid_601269 = validateParameter(valid_601269, JString, required = true,
                                 default = nil)
  if valid_601269 != nil:
    section.add "DomainName", valid_601269
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601270: Call_PostDescribeAvailabilityOptions_601257;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_601270.validator(path, query, header, formData, body)
  let scheme = call_601270.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601270.url(scheme.get, call_601270.host, call_601270.base,
                         call_601270.route, valid.getOrDefault("path"))
  result = hook(call_601270, url, valid)

proc call*(call_601271: Call_PostDescribeAvailabilityOptions_601257;
          DomainName: string; Action: string = "DescribeAvailabilityOptions";
          Version: string = "2011-02-01"): Recallable =
  ## postDescribeAvailabilityOptions
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601272 = newJObject()
  var formData_601273 = newJObject()
  add(formData_601273, "DomainName", newJString(DomainName))
  add(query_601272, "Action", newJString(Action))
  add(query_601272, "Version", newJString(Version))
  result = call_601271.call(nil, query_601272, nil, formData_601273, nil)

var postDescribeAvailabilityOptions* = Call_PostDescribeAvailabilityOptions_601257(
    name: "postDescribeAvailabilityOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeAvailabilityOptions",
    validator: validate_PostDescribeAvailabilityOptions_601258, base: "/",
    url: url_PostDescribeAvailabilityOptions_601259,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAvailabilityOptions_601241 = ref object of OpenApiRestCall_600426
proc url_GetDescribeAvailabilityOptions_601243(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeAvailabilityOptions_601242(path: JsonNode;
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
  var valid_601244 = query.getOrDefault("Action")
  valid_601244 = validateParameter(valid_601244, JString, required = true, default = newJString(
      "DescribeAvailabilityOptions"))
  if valid_601244 != nil:
    section.add "Action", valid_601244
  var valid_601245 = query.getOrDefault("DomainName")
  valid_601245 = validateParameter(valid_601245, JString, required = true,
                                 default = nil)
  if valid_601245 != nil:
    section.add "DomainName", valid_601245
  var valid_601246 = query.getOrDefault("Version")
  valid_601246 = validateParameter(valid_601246, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_601246 != nil:
    section.add "Version", valid_601246
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
  var valid_601247 = header.getOrDefault("X-Amz-Date")
  valid_601247 = validateParameter(valid_601247, JString, required = false,
                                 default = nil)
  if valid_601247 != nil:
    section.add "X-Amz-Date", valid_601247
  var valid_601248 = header.getOrDefault("X-Amz-Security-Token")
  valid_601248 = validateParameter(valid_601248, JString, required = false,
                                 default = nil)
  if valid_601248 != nil:
    section.add "X-Amz-Security-Token", valid_601248
  var valid_601249 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601249 = validateParameter(valid_601249, JString, required = false,
                                 default = nil)
  if valid_601249 != nil:
    section.add "X-Amz-Content-Sha256", valid_601249
  var valid_601250 = header.getOrDefault("X-Amz-Algorithm")
  valid_601250 = validateParameter(valid_601250, JString, required = false,
                                 default = nil)
  if valid_601250 != nil:
    section.add "X-Amz-Algorithm", valid_601250
  var valid_601251 = header.getOrDefault("X-Amz-Signature")
  valid_601251 = validateParameter(valid_601251, JString, required = false,
                                 default = nil)
  if valid_601251 != nil:
    section.add "X-Amz-Signature", valid_601251
  var valid_601252 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601252 = validateParameter(valid_601252, JString, required = false,
                                 default = nil)
  if valid_601252 != nil:
    section.add "X-Amz-SignedHeaders", valid_601252
  var valid_601253 = header.getOrDefault("X-Amz-Credential")
  valid_601253 = validateParameter(valid_601253, JString, required = false,
                                 default = nil)
  if valid_601253 != nil:
    section.add "X-Amz-Credential", valid_601253
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601254: Call_GetDescribeAvailabilityOptions_601241; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_601254.validator(path, query, header, formData, body)
  let scheme = call_601254.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601254.url(scheme.get, call_601254.host, call_601254.base,
                         call_601254.route, valid.getOrDefault("path"))
  result = hook(call_601254, url, valid)

proc call*(call_601255: Call_GetDescribeAvailabilityOptions_601241;
          DomainName: string; Action: string = "DescribeAvailabilityOptions";
          Version: string = "2011-02-01"): Recallable =
  ## getDescribeAvailabilityOptions
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_601256 = newJObject()
  add(query_601256, "Action", newJString(Action))
  add(query_601256, "DomainName", newJString(DomainName))
  add(query_601256, "Version", newJString(Version))
  result = call_601255.call(nil, query_601256, nil, nil, nil)

var getDescribeAvailabilityOptions* = Call_GetDescribeAvailabilityOptions_601241(
    name: "getDescribeAvailabilityOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeAvailabilityOptions",
    validator: validate_GetDescribeAvailabilityOptions_601242, base: "/",
    url: url_GetDescribeAvailabilityOptions_601243,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDefaultSearchField_601290 = ref object of OpenApiRestCall_600426
proc url_PostDescribeDefaultSearchField_601292(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDefaultSearchField_601291(path: JsonNode;
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
  var valid_601293 = query.getOrDefault("Action")
  valid_601293 = validateParameter(valid_601293, JString, required = true, default = newJString(
      "DescribeDefaultSearchField"))
  if valid_601293 != nil:
    section.add "Action", valid_601293
  var valid_601294 = query.getOrDefault("Version")
  valid_601294 = validateParameter(valid_601294, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_601294 != nil:
    section.add "Version", valid_601294
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
  var valid_601295 = header.getOrDefault("X-Amz-Date")
  valid_601295 = validateParameter(valid_601295, JString, required = false,
                                 default = nil)
  if valid_601295 != nil:
    section.add "X-Amz-Date", valid_601295
  var valid_601296 = header.getOrDefault("X-Amz-Security-Token")
  valid_601296 = validateParameter(valid_601296, JString, required = false,
                                 default = nil)
  if valid_601296 != nil:
    section.add "X-Amz-Security-Token", valid_601296
  var valid_601297 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601297 = validateParameter(valid_601297, JString, required = false,
                                 default = nil)
  if valid_601297 != nil:
    section.add "X-Amz-Content-Sha256", valid_601297
  var valid_601298 = header.getOrDefault("X-Amz-Algorithm")
  valid_601298 = validateParameter(valid_601298, JString, required = false,
                                 default = nil)
  if valid_601298 != nil:
    section.add "X-Amz-Algorithm", valid_601298
  var valid_601299 = header.getOrDefault("X-Amz-Signature")
  valid_601299 = validateParameter(valid_601299, JString, required = false,
                                 default = nil)
  if valid_601299 != nil:
    section.add "X-Amz-Signature", valid_601299
  var valid_601300 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601300 = validateParameter(valid_601300, JString, required = false,
                                 default = nil)
  if valid_601300 != nil:
    section.add "X-Amz-SignedHeaders", valid_601300
  var valid_601301 = header.getOrDefault("X-Amz-Credential")
  valid_601301 = validateParameter(valid_601301, JString, required = false,
                                 default = nil)
  if valid_601301 != nil:
    section.add "X-Amz-Credential", valid_601301
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_601302 = formData.getOrDefault("DomainName")
  valid_601302 = validateParameter(valid_601302, JString, required = true,
                                 default = nil)
  if valid_601302 != nil:
    section.add "DomainName", valid_601302
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601303: Call_PostDescribeDefaultSearchField_601290; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the default search field configured for the search domain.
  ## 
  let valid = call_601303.validator(path, query, header, formData, body)
  let scheme = call_601303.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601303.url(scheme.get, call_601303.host, call_601303.base,
                         call_601303.route, valid.getOrDefault("path"))
  result = hook(call_601303, url, valid)

proc call*(call_601304: Call_PostDescribeDefaultSearchField_601290;
          DomainName: string; Action: string = "DescribeDefaultSearchField";
          Version: string = "2011-02-01"): Recallable =
  ## postDescribeDefaultSearchField
  ## Gets the default search field configured for the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601305 = newJObject()
  var formData_601306 = newJObject()
  add(formData_601306, "DomainName", newJString(DomainName))
  add(query_601305, "Action", newJString(Action))
  add(query_601305, "Version", newJString(Version))
  result = call_601304.call(nil, query_601305, nil, formData_601306, nil)

var postDescribeDefaultSearchField* = Call_PostDescribeDefaultSearchField_601290(
    name: "postDescribeDefaultSearchField", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeDefaultSearchField",
    validator: validate_PostDescribeDefaultSearchField_601291, base: "/",
    url: url_PostDescribeDefaultSearchField_601292,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDefaultSearchField_601274 = ref object of OpenApiRestCall_600426
proc url_GetDescribeDefaultSearchField_601276(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDefaultSearchField_601275(path: JsonNode; query: JsonNode;
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
  var valid_601277 = query.getOrDefault("Action")
  valid_601277 = validateParameter(valid_601277, JString, required = true, default = newJString(
      "DescribeDefaultSearchField"))
  if valid_601277 != nil:
    section.add "Action", valid_601277
  var valid_601278 = query.getOrDefault("DomainName")
  valid_601278 = validateParameter(valid_601278, JString, required = true,
                                 default = nil)
  if valid_601278 != nil:
    section.add "DomainName", valid_601278
  var valid_601279 = query.getOrDefault("Version")
  valid_601279 = validateParameter(valid_601279, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_601279 != nil:
    section.add "Version", valid_601279
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
  var valid_601280 = header.getOrDefault("X-Amz-Date")
  valid_601280 = validateParameter(valid_601280, JString, required = false,
                                 default = nil)
  if valid_601280 != nil:
    section.add "X-Amz-Date", valid_601280
  var valid_601281 = header.getOrDefault("X-Amz-Security-Token")
  valid_601281 = validateParameter(valid_601281, JString, required = false,
                                 default = nil)
  if valid_601281 != nil:
    section.add "X-Amz-Security-Token", valid_601281
  var valid_601282 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601282 = validateParameter(valid_601282, JString, required = false,
                                 default = nil)
  if valid_601282 != nil:
    section.add "X-Amz-Content-Sha256", valid_601282
  var valid_601283 = header.getOrDefault("X-Amz-Algorithm")
  valid_601283 = validateParameter(valid_601283, JString, required = false,
                                 default = nil)
  if valid_601283 != nil:
    section.add "X-Amz-Algorithm", valid_601283
  var valid_601284 = header.getOrDefault("X-Amz-Signature")
  valid_601284 = validateParameter(valid_601284, JString, required = false,
                                 default = nil)
  if valid_601284 != nil:
    section.add "X-Amz-Signature", valid_601284
  var valid_601285 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601285 = validateParameter(valid_601285, JString, required = false,
                                 default = nil)
  if valid_601285 != nil:
    section.add "X-Amz-SignedHeaders", valid_601285
  var valid_601286 = header.getOrDefault("X-Amz-Credential")
  valid_601286 = validateParameter(valid_601286, JString, required = false,
                                 default = nil)
  if valid_601286 != nil:
    section.add "X-Amz-Credential", valid_601286
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601287: Call_GetDescribeDefaultSearchField_601274; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the default search field configured for the search domain.
  ## 
  let valid = call_601287.validator(path, query, header, formData, body)
  let scheme = call_601287.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601287.url(scheme.get, call_601287.host, call_601287.base,
                         call_601287.route, valid.getOrDefault("path"))
  result = hook(call_601287, url, valid)

proc call*(call_601288: Call_GetDescribeDefaultSearchField_601274;
          DomainName: string; Action: string = "DescribeDefaultSearchField";
          Version: string = "2011-02-01"): Recallable =
  ## getDescribeDefaultSearchField
  ## Gets the default search field configured for the search domain.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_601289 = newJObject()
  add(query_601289, "Action", newJString(Action))
  add(query_601289, "DomainName", newJString(DomainName))
  add(query_601289, "Version", newJString(Version))
  result = call_601288.call(nil, query_601289, nil, nil, nil)

var getDescribeDefaultSearchField* = Call_GetDescribeDefaultSearchField_601274(
    name: "getDescribeDefaultSearchField", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeDefaultSearchField",
    validator: validate_GetDescribeDefaultSearchField_601275, base: "/",
    url: url_GetDescribeDefaultSearchField_601276,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDomains_601323 = ref object of OpenApiRestCall_600426
proc url_PostDescribeDomains_601325(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeDomains_601324(path: JsonNode; query: JsonNode;
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
  var valid_601326 = query.getOrDefault("Action")
  valid_601326 = validateParameter(valid_601326, JString, required = true,
                                 default = newJString("DescribeDomains"))
  if valid_601326 != nil:
    section.add "Action", valid_601326
  var valid_601327 = query.getOrDefault("Version")
  valid_601327 = validateParameter(valid_601327, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_601327 != nil:
    section.add "Version", valid_601327
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
  var valid_601328 = header.getOrDefault("X-Amz-Date")
  valid_601328 = validateParameter(valid_601328, JString, required = false,
                                 default = nil)
  if valid_601328 != nil:
    section.add "X-Amz-Date", valid_601328
  var valid_601329 = header.getOrDefault("X-Amz-Security-Token")
  valid_601329 = validateParameter(valid_601329, JString, required = false,
                                 default = nil)
  if valid_601329 != nil:
    section.add "X-Amz-Security-Token", valid_601329
  var valid_601330 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601330 = validateParameter(valid_601330, JString, required = false,
                                 default = nil)
  if valid_601330 != nil:
    section.add "X-Amz-Content-Sha256", valid_601330
  var valid_601331 = header.getOrDefault("X-Amz-Algorithm")
  valid_601331 = validateParameter(valid_601331, JString, required = false,
                                 default = nil)
  if valid_601331 != nil:
    section.add "X-Amz-Algorithm", valid_601331
  var valid_601332 = header.getOrDefault("X-Amz-Signature")
  valid_601332 = validateParameter(valid_601332, JString, required = false,
                                 default = nil)
  if valid_601332 != nil:
    section.add "X-Amz-Signature", valid_601332
  var valid_601333 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601333 = validateParameter(valid_601333, JString, required = false,
                                 default = nil)
  if valid_601333 != nil:
    section.add "X-Amz-SignedHeaders", valid_601333
  var valid_601334 = header.getOrDefault("X-Amz-Credential")
  valid_601334 = validateParameter(valid_601334, JString, required = false,
                                 default = nil)
  if valid_601334 != nil:
    section.add "X-Amz-Credential", valid_601334
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainNames: JArray
  ##              : A list of domain names.
  section = newJObject()
  var valid_601335 = formData.getOrDefault("DomainNames")
  valid_601335 = validateParameter(valid_601335, JArray, required = false,
                                 default = nil)
  if valid_601335 != nil:
    section.add "DomainNames", valid_601335
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601336: Call_PostDescribeDomains_601323; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default.
  ## 
  let valid = call_601336.validator(path, query, header, formData, body)
  let scheme = call_601336.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601336.url(scheme.get, call_601336.host, call_601336.base,
                         call_601336.route, valid.getOrDefault("path"))
  result = hook(call_601336, url, valid)

proc call*(call_601337: Call_PostDescribeDomains_601323;
          DomainNames: JsonNode = nil; Action: string = "DescribeDomains";
          Version: string = "2011-02-01"): Recallable =
  ## postDescribeDomains
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default.
  ##   DomainNames: JArray
  ##              : A list of domain names.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601338 = newJObject()
  var formData_601339 = newJObject()
  if DomainNames != nil:
    formData_601339.add "DomainNames", DomainNames
  add(query_601338, "Action", newJString(Action))
  add(query_601338, "Version", newJString(Version))
  result = call_601337.call(nil, query_601338, nil, formData_601339, nil)

var postDescribeDomains* = Call_PostDescribeDomains_601323(
    name: "postDescribeDomains", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeDomains",
    validator: validate_PostDescribeDomains_601324, base: "/",
    url: url_PostDescribeDomains_601325, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDomains_601307 = ref object of OpenApiRestCall_600426
proc url_GetDescribeDomains_601309(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeDomains_601308(path: JsonNode; query: JsonNode;
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
  var valid_601310 = query.getOrDefault("DomainNames")
  valid_601310 = validateParameter(valid_601310, JArray, required = false,
                                 default = nil)
  if valid_601310 != nil:
    section.add "DomainNames", valid_601310
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601311 = query.getOrDefault("Action")
  valid_601311 = validateParameter(valid_601311, JString, required = true,
                                 default = newJString("DescribeDomains"))
  if valid_601311 != nil:
    section.add "Action", valid_601311
  var valid_601312 = query.getOrDefault("Version")
  valid_601312 = validateParameter(valid_601312, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_601312 != nil:
    section.add "Version", valid_601312
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
  var valid_601313 = header.getOrDefault("X-Amz-Date")
  valid_601313 = validateParameter(valid_601313, JString, required = false,
                                 default = nil)
  if valid_601313 != nil:
    section.add "X-Amz-Date", valid_601313
  var valid_601314 = header.getOrDefault("X-Amz-Security-Token")
  valid_601314 = validateParameter(valid_601314, JString, required = false,
                                 default = nil)
  if valid_601314 != nil:
    section.add "X-Amz-Security-Token", valid_601314
  var valid_601315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601315 = validateParameter(valid_601315, JString, required = false,
                                 default = nil)
  if valid_601315 != nil:
    section.add "X-Amz-Content-Sha256", valid_601315
  var valid_601316 = header.getOrDefault("X-Amz-Algorithm")
  valid_601316 = validateParameter(valid_601316, JString, required = false,
                                 default = nil)
  if valid_601316 != nil:
    section.add "X-Amz-Algorithm", valid_601316
  var valid_601317 = header.getOrDefault("X-Amz-Signature")
  valid_601317 = validateParameter(valid_601317, JString, required = false,
                                 default = nil)
  if valid_601317 != nil:
    section.add "X-Amz-Signature", valid_601317
  var valid_601318 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601318 = validateParameter(valid_601318, JString, required = false,
                                 default = nil)
  if valid_601318 != nil:
    section.add "X-Amz-SignedHeaders", valid_601318
  var valid_601319 = header.getOrDefault("X-Amz-Credential")
  valid_601319 = validateParameter(valid_601319, JString, required = false,
                                 default = nil)
  if valid_601319 != nil:
    section.add "X-Amz-Credential", valid_601319
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601320: Call_GetDescribeDomains_601307; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default.
  ## 
  let valid = call_601320.validator(path, query, header, formData, body)
  let scheme = call_601320.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601320.url(scheme.get, call_601320.host, call_601320.base,
                         call_601320.route, valid.getOrDefault("path"))
  result = hook(call_601320, url, valid)

proc call*(call_601321: Call_GetDescribeDomains_601307;
          DomainNames: JsonNode = nil; Action: string = "DescribeDomains";
          Version: string = "2011-02-01"): Recallable =
  ## getDescribeDomains
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default.
  ##   DomainNames: JArray
  ##              : A list of domain names.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601322 = newJObject()
  if DomainNames != nil:
    query_601322.add "DomainNames", DomainNames
  add(query_601322, "Action", newJString(Action))
  add(query_601322, "Version", newJString(Version))
  result = call_601321.call(nil, query_601322, nil, nil, nil)

var getDescribeDomains* = Call_GetDescribeDomains_601307(
    name: "getDescribeDomains", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeDomains",
    validator: validate_GetDescribeDomains_601308, base: "/",
    url: url_GetDescribeDomains_601309, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeIndexFields_601357 = ref object of OpenApiRestCall_600426
proc url_PostDescribeIndexFields_601359(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeIndexFields_601358(path: JsonNode; query: JsonNode;
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
  var valid_601360 = query.getOrDefault("Action")
  valid_601360 = validateParameter(valid_601360, JString, required = true,
                                 default = newJString("DescribeIndexFields"))
  if valid_601360 != nil:
    section.add "Action", valid_601360
  var valid_601361 = query.getOrDefault("Version")
  valid_601361 = validateParameter(valid_601361, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_601361 != nil:
    section.add "Version", valid_601361
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
  var valid_601362 = header.getOrDefault("X-Amz-Date")
  valid_601362 = validateParameter(valid_601362, JString, required = false,
                                 default = nil)
  if valid_601362 != nil:
    section.add "X-Amz-Date", valid_601362
  var valid_601363 = header.getOrDefault("X-Amz-Security-Token")
  valid_601363 = validateParameter(valid_601363, JString, required = false,
                                 default = nil)
  if valid_601363 != nil:
    section.add "X-Amz-Security-Token", valid_601363
  var valid_601364 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601364 = validateParameter(valid_601364, JString, required = false,
                                 default = nil)
  if valid_601364 != nil:
    section.add "X-Amz-Content-Sha256", valid_601364
  var valid_601365 = header.getOrDefault("X-Amz-Algorithm")
  valid_601365 = validateParameter(valid_601365, JString, required = false,
                                 default = nil)
  if valid_601365 != nil:
    section.add "X-Amz-Algorithm", valid_601365
  var valid_601366 = header.getOrDefault("X-Amz-Signature")
  valid_601366 = validateParameter(valid_601366, JString, required = false,
                                 default = nil)
  if valid_601366 != nil:
    section.add "X-Amz-Signature", valid_601366
  var valid_601367 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601367 = validateParameter(valid_601367, JString, required = false,
                                 default = nil)
  if valid_601367 != nil:
    section.add "X-Amz-SignedHeaders", valid_601367
  var valid_601368 = header.getOrDefault("X-Amz-Credential")
  valid_601368 = validateParameter(valid_601368, JString, required = false,
                                 default = nil)
  if valid_601368 != nil:
    section.add "X-Amz-Credential", valid_601368
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   FieldNames: JArray
  ##             : Limits the <code>DescribeIndexFields</code> response to the specified fields.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_601369 = formData.getOrDefault("DomainName")
  valid_601369 = validateParameter(valid_601369, JString, required = true,
                                 default = nil)
  if valid_601369 != nil:
    section.add "DomainName", valid_601369
  var valid_601370 = formData.getOrDefault("FieldNames")
  valid_601370 = validateParameter(valid_601370, JArray, required = false,
                                 default = nil)
  if valid_601370 != nil:
    section.add "FieldNames", valid_601370
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601371: Call_PostDescribeIndexFields_601357; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. Shows all fields by default.
  ## 
  let valid = call_601371.validator(path, query, header, formData, body)
  let scheme = call_601371.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601371.url(scheme.get, call_601371.host, call_601371.base,
                         call_601371.route, valid.getOrDefault("path"))
  result = hook(call_601371, url, valid)

proc call*(call_601372: Call_PostDescribeIndexFields_601357; DomainName: string;
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
  var query_601373 = newJObject()
  var formData_601374 = newJObject()
  add(formData_601374, "DomainName", newJString(DomainName))
  add(query_601373, "Action", newJString(Action))
  if FieldNames != nil:
    formData_601374.add "FieldNames", FieldNames
  add(query_601373, "Version", newJString(Version))
  result = call_601372.call(nil, query_601373, nil, formData_601374, nil)

var postDescribeIndexFields* = Call_PostDescribeIndexFields_601357(
    name: "postDescribeIndexFields", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeIndexFields",
    validator: validate_PostDescribeIndexFields_601358, base: "/",
    url: url_PostDescribeIndexFields_601359, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeIndexFields_601340 = ref object of OpenApiRestCall_600426
proc url_GetDescribeIndexFields_601342(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeIndexFields_601341(path: JsonNode; query: JsonNode;
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
  var valid_601343 = query.getOrDefault("FieldNames")
  valid_601343 = validateParameter(valid_601343, JArray, required = false,
                                 default = nil)
  if valid_601343 != nil:
    section.add "FieldNames", valid_601343
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601344 = query.getOrDefault("Action")
  valid_601344 = validateParameter(valid_601344, JString, required = true,
                                 default = newJString("DescribeIndexFields"))
  if valid_601344 != nil:
    section.add "Action", valid_601344
  var valid_601345 = query.getOrDefault("DomainName")
  valid_601345 = validateParameter(valid_601345, JString, required = true,
                                 default = nil)
  if valid_601345 != nil:
    section.add "DomainName", valid_601345
  var valid_601346 = query.getOrDefault("Version")
  valid_601346 = validateParameter(valid_601346, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_601346 != nil:
    section.add "Version", valid_601346
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
  var valid_601347 = header.getOrDefault("X-Amz-Date")
  valid_601347 = validateParameter(valid_601347, JString, required = false,
                                 default = nil)
  if valid_601347 != nil:
    section.add "X-Amz-Date", valid_601347
  var valid_601348 = header.getOrDefault("X-Amz-Security-Token")
  valid_601348 = validateParameter(valid_601348, JString, required = false,
                                 default = nil)
  if valid_601348 != nil:
    section.add "X-Amz-Security-Token", valid_601348
  var valid_601349 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601349 = validateParameter(valid_601349, JString, required = false,
                                 default = nil)
  if valid_601349 != nil:
    section.add "X-Amz-Content-Sha256", valid_601349
  var valid_601350 = header.getOrDefault("X-Amz-Algorithm")
  valid_601350 = validateParameter(valid_601350, JString, required = false,
                                 default = nil)
  if valid_601350 != nil:
    section.add "X-Amz-Algorithm", valid_601350
  var valid_601351 = header.getOrDefault("X-Amz-Signature")
  valid_601351 = validateParameter(valid_601351, JString, required = false,
                                 default = nil)
  if valid_601351 != nil:
    section.add "X-Amz-Signature", valid_601351
  var valid_601352 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601352 = validateParameter(valid_601352, JString, required = false,
                                 default = nil)
  if valid_601352 != nil:
    section.add "X-Amz-SignedHeaders", valid_601352
  var valid_601353 = header.getOrDefault("X-Amz-Credential")
  valid_601353 = validateParameter(valid_601353, JString, required = false,
                                 default = nil)
  if valid_601353 != nil:
    section.add "X-Amz-Credential", valid_601353
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601354: Call_GetDescribeIndexFields_601340; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. Shows all fields by default.
  ## 
  let valid = call_601354.validator(path, query, header, formData, body)
  let scheme = call_601354.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601354.url(scheme.get, call_601354.host, call_601354.base,
                         call_601354.route, valid.getOrDefault("path"))
  result = hook(call_601354, url, valid)

proc call*(call_601355: Call_GetDescribeIndexFields_601340; DomainName: string;
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
  var query_601356 = newJObject()
  if FieldNames != nil:
    query_601356.add "FieldNames", FieldNames
  add(query_601356, "Action", newJString(Action))
  add(query_601356, "DomainName", newJString(DomainName))
  add(query_601356, "Version", newJString(Version))
  result = call_601355.call(nil, query_601356, nil, nil, nil)

var getDescribeIndexFields* = Call_GetDescribeIndexFields_601340(
    name: "getDescribeIndexFields", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeIndexFields",
    validator: validate_GetDescribeIndexFields_601341, base: "/",
    url: url_GetDescribeIndexFields_601342, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeRankExpressions_601392 = ref object of OpenApiRestCall_600426
proc url_PostDescribeRankExpressions_601394(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeRankExpressions_601393(path: JsonNode; query: JsonNode;
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
  var valid_601395 = query.getOrDefault("Action")
  valid_601395 = validateParameter(valid_601395, JString, required = true, default = newJString(
      "DescribeRankExpressions"))
  if valid_601395 != nil:
    section.add "Action", valid_601395
  var valid_601396 = query.getOrDefault("Version")
  valid_601396 = validateParameter(valid_601396, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_601396 != nil:
    section.add "Version", valid_601396
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
  var valid_601397 = header.getOrDefault("X-Amz-Date")
  valid_601397 = validateParameter(valid_601397, JString, required = false,
                                 default = nil)
  if valid_601397 != nil:
    section.add "X-Amz-Date", valid_601397
  var valid_601398 = header.getOrDefault("X-Amz-Security-Token")
  valid_601398 = validateParameter(valid_601398, JString, required = false,
                                 default = nil)
  if valid_601398 != nil:
    section.add "X-Amz-Security-Token", valid_601398
  var valid_601399 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601399 = validateParameter(valid_601399, JString, required = false,
                                 default = nil)
  if valid_601399 != nil:
    section.add "X-Amz-Content-Sha256", valid_601399
  var valid_601400 = header.getOrDefault("X-Amz-Algorithm")
  valid_601400 = validateParameter(valid_601400, JString, required = false,
                                 default = nil)
  if valid_601400 != nil:
    section.add "X-Amz-Algorithm", valid_601400
  var valid_601401 = header.getOrDefault("X-Amz-Signature")
  valid_601401 = validateParameter(valid_601401, JString, required = false,
                                 default = nil)
  if valid_601401 != nil:
    section.add "X-Amz-Signature", valid_601401
  var valid_601402 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601402 = validateParameter(valid_601402, JString, required = false,
                                 default = nil)
  if valid_601402 != nil:
    section.add "X-Amz-SignedHeaders", valid_601402
  var valid_601403 = header.getOrDefault("X-Amz-Credential")
  valid_601403 = validateParameter(valid_601403, JString, required = false,
                                 default = nil)
  if valid_601403 != nil:
    section.add "X-Amz-Credential", valid_601403
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   RankNames: JArray
  ##            : Limits the <code>DescribeRankExpressions</code> response to the specified fields.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_601404 = formData.getOrDefault("DomainName")
  valid_601404 = validateParameter(valid_601404, JString, required = true,
                                 default = nil)
  if valid_601404 != nil:
    section.add "DomainName", valid_601404
  var valid_601405 = formData.getOrDefault("RankNames")
  valid_601405 = validateParameter(valid_601405, JArray, required = false,
                                 default = nil)
  if valid_601405 != nil:
    section.add "RankNames", valid_601405
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601406: Call_PostDescribeRankExpressions_601392; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the rank expressions configured for the search domain. Can be limited to specific rank expressions by name. Shows all rank expressions by default. 
  ## 
  let valid = call_601406.validator(path, query, header, formData, body)
  let scheme = call_601406.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601406.url(scheme.get, call_601406.host, call_601406.base,
                         call_601406.route, valid.getOrDefault("path"))
  result = hook(call_601406, url, valid)

proc call*(call_601407: Call_PostDescribeRankExpressions_601392;
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
  var query_601408 = newJObject()
  var formData_601409 = newJObject()
  add(formData_601409, "DomainName", newJString(DomainName))
  add(query_601408, "Action", newJString(Action))
  if RankNames != nil:
    formData_601409.add "RankNames", RankNames
  add(query_601408, "Version", newJString(Version))
  result = call_601407.call(nil, query_601408, nil, formData_601409, nil)

var postDescribeRankExpressions* = Call_PostDescribeRankExpressions_601392(
    name: "postDescribeRankExpressions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeRankExpressions",
    validator: validate_PostDescribeRankExpressions_601393, base: "/",
    url: url_PostDescribeRankExpressions_601394,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeRankExpressions_601375 = ref object of OpenApiRestCall_600426
proc url_GetDescribeRankExpressions_601377(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeRankExpressions_601376(path: JsonNode; query: JsonNode;
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
  var valid_601378 = query.getOrDefault("RankNames")
  valid_601378 = validateParameter(valid_601378, JArray, required = false,
                                 default = nil)
  if valid_601378 != nil:
    section.add "RankNames", valid_601378
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_601379 = query.getOrDefault("Action")
  valid_601379 = validateParameter(valid_601379, JString, required = true, default = newJString(
      "DescribeRankExpressions"))
  if valid_601379 != nil:
    section.add "Action", valid_601379
  var valid_601380 = query.getOrDefault("DomainName")
  valid_601380 = validateParameter(valid_601380, JString, required = true,
                                 default = nil)
  if valid_601380 != nil:
    section.add "DomainName", valid_601380
  var valid_601381 = query.getOrDefault("Version")
  valid_601381 = validateParameter(valid_601381, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_601381 != nil:
    section.add "Version", valid_601381
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
  var valid_601382 = header.getOrDefault("X-Amz-Date")
  valid_601382 = validateParameter(valid_601382, JString, required = false,
                                 default = nil)
  if valid_601382 != nil:
    section.add "X-Amz-Date", valid_601382
  var valid_601383 = header.getOrDefault("X-Amz-Security-Token")
  valid_601383 = validateParameter(valid_601383, JString, required = false,
                                 default = nil)
  if valid_601383 != nil:
    section.add "X-Amz-Security-Token", valid_601383
  var valid_601384 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601384 = validateParameter(valid_601384, JString, required = false,
                                 default = nil)
  if valid_601384 != nil:
    section.add "X-Amz-Content-Sha256", valid_601384
  var valid_601385 = header.getOrDefault("X-Amz-Algorithm")
  valid_601385 = validateParameter(valid_601385, JString, required = false,
                                 default = nil)
  if valid_601385 != nil:
    section.add "X-Amz-Algorithm", valid_601385
  var valid_601386 = header.getOrDefault("X-Amz-Signature")
  valid_601386 = validateParameter(valid_601386, JString, required = false,
                                 default = nil)
  if valid_601386 != nil:
    section.add "X-Amz-Signature", valid_601386
  var valid_601387 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601387 = validateParameter(valid_601387, JString, required = false,
                                 default = nil)
  if valid_601387 != nil:
    section.add "X-Amz-SignedHeaders", valid_601387
  var valid_601388 = header.getOrDefault("X-Amz-Credential")
  valid_601388 = validateParameter(valid_601388, JString, required = false,
                                 default = nil)
  if valid_601388 != nil:
    section.add "X-Amz-Credential", valid_601388
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601389: Call_GetDescribeRankExpressions_601375; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the rank expressions configured for the search domain. Can be limited to specific rank expressions by name. Shows all rank expressions by default. 
  ## 
  let valid = call_601389.validator(path, query, header, formData, body)
  let scheme = call_601389.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601389.url(scheme.get, call_601389.host, call_601389.base,
                         call_601389.route, valid.getOrDefault("path"))
  result = hook(call_601389, url, valid)

proc call*(call_601390: Call_GetDescribeRankExpressions_601375; DomainName: string;
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
  var query_601391 = newJObject()
  if RankNames != nil:
    query_601391.add "RankNames", RankNames
  add(query_601391, "Action", newJString(Action))
  add(query_601391, "DomainName", newJString(DomainName))
  add(query_601391, "Version", newJString(Version))
  result = call_601390.call(nil, query_601391, nil, nil, nil)

var getDescribeRankExpressions* = Call_GetDescribeRankExpressions_601375(
    name: "getDescribeRankExpressions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeRankExpressions",
    validator: validate_GetDescribeRankExpressions_601376, base: "/",
    url: url_GetDescribeRankExpressions_601377,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeServiceAccessPolicies_601426 = ref object of OpenApiRestCall_600426
proc url_PostDescribeServiceAccessPolicies_601428(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeServiceAccessPolicies_601427(path: JsonNode;
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
  var valid_601429 = query.getOrDefault("Action")
  valid_601429 = validateParameter(valid_601429, JString, required = true, default = newJString(
      "DescribeServiceAccessPolicies"))
  if valid_601429 != nil:
    section.add "Action", valid_601429
  var valid_601430 = query.getOrDefault("Version")
  valid_601430 = validateParameter(valid_601430, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_601430 != nil:
    section.add "Version", valid_601430
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
  var valid_601431 = header.getOrDefault("X-Amz-Date")
  valid_601431 = validateParameter(valid_601431, JString, required = false,
                                 default = nil)
  if valid_601431 != nil:
    section.add "X-Amz-Date", valid_601431
  var valid_601432 = header.getOrDefault("X-Amz-Security-Token")
  valid_601432 = validateParameter(valid_601432, JString, required = false,
                                 default = nil)
  if valid_601432 != nil:
    section.add "X-Amz-Security-Token", valid_601432
  var valid_601433 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601433 = validateParameter(valid_601433, JString, required = false,
                                 default = nil)
  if valid_601433 != nil:
    section.add "X-Amz-Content-Sha256", valid_601433
  var valid_601434 = header.getOrDefault("X-Amz-Algorithm")
  valid_601434 = validateParameter(valid_601434, JString, required = false,
                                 default = nil)
  if valid_601434 != nil:
    section.add "X-Amz-Algorithm", valid_601434
  var valid_601435 = header.getOrDefault("X-Amz-Signature")
  valid_601435 = validateParameter(valid_601435, JString, required = false,
                                 default = nil)
  if valid_601435 != nil:
    section.add "X-Amz-Signature", valid_601435
  var valid_601436 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601436 = validateParameter(valid_601436, JString, required = false,
                                 default = nil)
  if valid_601436 != nil:
    section.add "X-Amz-SignedHeaders", valid_601436
  var valid_601437 = header.getOrDefault("X-Amz-Credential")
  valid_601437 = validateParameter(valid_601437, JString, required = false,
                                 default = nil)
  if valid_601437 != nil:
    section.add "X-Amz-Credential", valid_601437
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_601438 = formData.getOrDefault("DomainName")
  valid_601438 = validateParameter(valid_601438, JString, required = true,
                                 default = nil)
  if valid_601438 != nil:
    section.add "DomainName", valid_601438
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601439: Call_PostDescribeServiceAccessPolicies_601426;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets information about the resource-based policies that control access to the domain's document and search services.
  ## 
  let valid = call_601439.validator(path, query, header, formData, body)
  let scheme = call_601439.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601439.url(scheme.get, call_601439.host, call_601439.base,
                         call_601439.route, valid.getOrDefault("path"))
  result = hook(call_601439, url, valid)

proc call*(call_601440: Call_PostDescribeServiceAccessPolicies_601426;
          DomainName: string; Action: string = "DescribeServiceAccessPolicies";
          Version: string = "2011-02-01"): Recallable =
  ## postDescribeServiceAccessPolicies
  ## Gets information about the resource-based policies that control access to the domain's document and search services.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601441 = newJObject()
  var formData_601442 = newJObject()
  add(formData_601442, "DomainName", newJString(DomainName))
  add(query_601441, "Action", newJString(Action))
  add(query_601441, "Version", newJString(Version))
  result = call_601440.call(nil, query_601441, nil, formData_601442, nil)

var postDescribeServiceAccessPolicies* = Call_PostDescribeServiceAccessPolicies_601426(
    name: "postDescribeServiceAccessPolicies", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeServiceAccessPolicies",
    validator: validate_PostDescribeServiceAccessPolicies_601427, base: "/",
    url: url_PostDescribeServiceAccessPolicies_601428,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeServiceAccessPolicies_601410 = ref object of OpenApiRestCall_600426
proc url_GetDescribeServiceAccessPolicies_601412(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeServiceAccessPolicies_601411(path: JsonNode;
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
  var valid_601413 = query.getOrDefault("Action")
  valid_601413 = validateParameter(valid_601413, JString, required = true, default = newJString(
      "DescribeServiceAccessPolicies"))
  if valid_601413 != nil:
    section.add "Action", valid_601413
  var valid_601414 = query.getOrDefault("DomainName")
  valid_601414 = validateParameter(valid_601414, JString, required = true,
                                 default = nil)
  if valid_601414 != nil:
    section.add "DomainName", valid_601414
  var valid_601415 = query.getOrDefault("Version")
  valid_601415 = validateParameter(valid_601415, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_601415 != nil:
    section.add "Version", valid_601415
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
  var valid_601416 = header.getOrDefault("X-Amz-Date")
  valid_601416 = validateParameter(valid_601416, JString, required = false,
                                 default = nil)
  if valid_601416 != nil:
    section.add "X-Amz-Date", valid_601416
  var valid_601417 = header.getOrDefault("X-Amz-Security-Token")
  valid_601417 = validateParameter(valid_601417, JString, required = false,
                                 default = nil)
  if valid_601417 != nil:
    section.add "X-Amz-Security-Token", valid_601417
  var valid_601418 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601418 = validateParameter(valid_601418, JString, required = false,
                                 default = nil)
  if valid_601418 != nil:
    section.add "X-Amz-Content-Sha256", valid_601418
  var valid_601419 = header.getOrDefault("X-Amz-Algorithm")
  valid_601419 = validateParameter(valid_601419, JString, required = false,
                                 default = nil)
  if valid_601419 != nil:
    section.add "X-Amz-Algorithm", valid_601419
  var valid_601420 = header.getOrDefault("X-Amz-Signature")
  valid_601420 = validateParameter(valid_601420, JString, required = false,
                                 default = nil)
  if valid_601420 != nil:
    section.add "X-Amz-Signature", valid_601420
  var valid_601421 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601421 = validateParameter(valid_601421, JString, required = false,
                                 default = nil)
  if valid_601421 != nil:
    section.add "X-Amz-SignedHeaders", valid_601421
  var valid_601422 = header.getOrDefault("X-Amz-Credential")
  valid_601422 = validateParameter(valid_601422, JString, required = false,
                                 default = nil)
  if valid_601422 != nil:
    section.add "X-Amz-Credential", valid_601422
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601423: Call_GetDescribeServiceAccessPolicies_601410;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets information about the resource-based policies that control access to the domain's document and search services.
  ## 
  let valid = call_601423.validator(path, query, header, formData, body)
  let scheme = call_601423.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601423.url(scheme.get, call_601423.host, call_601423.base,
                         call_601423.route, valid.getOrDefault("path"))
  result = hook(call_601423, url, valid)

proc call*(call_601424: Call_GetDescribeServiceAccessPolicies_601410;
          DomainName: string; Action: string = "DescribeServiceAccessPolicies";
          Version: string = "2011-02-01"): Recallable =
  ## getDescribeServiceAccessPolicies
  ## Gets information about the resource-based policies that control access to the domain's document and search services.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_601425 = newJObject()
  add(query_601425, "Action", newJString(Action))
  add(query_601425, "DomainName", newJString(DomainName))
  add(query_601425, "Version", newJString(Version))
  result = call_601424.call(nil, query_601425, nil, nil, nil)

var getDescribeServiceAccessPolicies* = Call_GetDescribeServiceAccessPolicies_601410(
    name: "getDescribeServiceAccessPolicies", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeServiceAccessPolicies",
    validator: validate_GetDescribeServiceAccessPolicies_601411, base: "/",
    url: url_GetDescribeServiceAccessPolicies_601412,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeStemmingOptions_601459 = ref object of OpenApiRestCall_600426
proc url_PostDescribeStemmingOptions_601461(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeStemmingOptions_601460(path: JsonNode; query: JsonNode;
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
  var valid_601462 = query.getOrDefault("Action")
  valid_601462 = validateParameter(valid_601462, JString, required = true, default = newJString(
      "DescribeStemmingOptions"))
  if valid_601462 != nil:
    section.add "Action", valid_601462
  var valid_601463 = query.getOrDefault("Version")
  valid_601463 = validateParameter(valid_601463, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_601463 != nil:
    section.add "Version", valid_601463
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
  var valid_601464 = header.getOrDefault("X-Amz-Date")
  valid_601464 = validateParameter(valid_601464, JString, required = false,
                                 default = nil)
  if valid_601464 != nil:
    section.add "X-Amz-Date", valid_601464
  var valid_601465 = header.getOrDefault("X-Amz-Security-Token")
  valid_601465 = validateParameter(valid_601465, JString, required = false,
                                 default = nil)
  if valid_601465 != nil:
    section.add "X-Amz-Security-Token", valid_601465
  var valid_601466 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601466 = validateParameter(valid_601466, JString, required = false,
                                 default = nil)
  if valid_601466 != nil:
    section.add "X-Amz-Content-Sha256", valid_601466
  var valid_601467 = header.getOrDefault("X-Amz-Algorithm")
  valid_601467 = validateParameter(valid_601467, JString, required = false,
                                 default = nil)
  if valid_601467 != nil:
    section.add "X-Amz-Algorithm", valid_601467
  var valid_601468 = header.getOrDefault("X-Amz-Signature")
  valid_601468 = validateParameter(valid_601468, JString, required = false,
                                 default = nil)
  if valid_601468 != nil:
    section.add "X-Amz-Signature", valid_601468
  var valid_601469 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601469 = validateParameter(valid_601469, JString, required = false,
                                 default = nil)
  if valid_601469 != nil:
    section.add "X-Amz-SignedHeaders", valid_601469
  var valid_601470 = header.getOrDefault("X-Amz-Credential")
  valid_601470 = validateParameter(valid_601470, JString, required = false,
                                 default = nil)
  if valid_601470 != nil:
    section.add "X-Amz-Credential", valid_601470
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_601471 = formData.getOrDefault("DomainName")
  valid_601471 = validateParameter(valid_601471, JString, required = true,
                                 default = nil)
  if valid_601471 != nil:
    section.add "DomainName", valid_601471
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601472: Call_PostDescribeStemmingOptions_601459; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the stemming dictionary configured for the search domain.
  ## 
  let valid = call_601472.validator(path, query, header, formData, body)
  let scheme = call_601472.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601472.url(scheme.get, call_601472.host, call_601472.base,
                         call_601472.route, valid.getOrDefault("path"))
  result = hook(call_601472, url, valid)

proc call*(call_601473: Call_PostDescribeStemmingOptions_601459;
          DomainName: string; Action: string = "DescribeStemmingOptions";
          Version: string = "2011-02-01"): Recallable =
  ## postDescribeStemmingOptions
  ## Gets the stemming dictionary configured for the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601474 = newJObject()
  var formData_601475 = newJObject()
  add(formData_601475, "DomainName", newJString(DomainName))
  add(query_601474, "Action", newJString(Action))
  add(query_601474, "Version", newJString(Version))
  result = call_601473.call(nil, query_601474, nil, formData_601475, nil)

var postDescribeStemmingOptions* = Call_PostDescribeStemmingOptions_601459(
    name: "postDescribeStemmingOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeStemmingOptions",
    validator: validate_PostDescribeStemmingOptions_601460, base: "/",
    url: url_PostDescribeStemmingOptions_601461,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeStemmingOptions_601443 = ref object of OpenApiRestCall_600426
proc url_GetDescribeStemmingOptions_601445(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeStemmingOptions_601444(path: JsonNode; query: JsonNode;
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
  var valid_601446 = query.getOrDefault("Action")
  valid_601446 = validateParameter(valid_601446, JString, required = true, default = newJString(
      "DescribeStemmingOptions"))
  if valid_601446 != nil:
    section.add "Action", valid_601446
  var valid_601447 = query.getOrDefault("DomainName")
  valid_601447 = validateParameter(valid_601447, JString, required = true,
                                 default = nil)
  if valid_601447 != nil:
    section.add "DomainName", valid_601447
  var valid_601448 = query.getOrDefault("Version")
  valid_601448 = validateParameter(valid_601448, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_601448 != nil:
    section.add "Version", valid_601448
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
  var valid_601449 = header.getOrDefault("X-Amz-Date")
  valid_601449 = validateParameter(valid_601449, JString, required = false,
                                 default = nil)
  if valid_601449 != nil:
    section.add "X-Amz-Date", valid_601449
  var valid_601450 = header.getOrDefault("X-Amz-Security-Token")
  valid_601450 = validateParameter(valid_601450, JString, required = false,
                                 default = nil)
  if valid_601450 != nil:
    section.add "X-Amz-Security-Token", valid_601450
  var valid_601451 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601451 = validateParameter(valid_601451, JString, required = false,
                                 default = nil)
  if valid_601451 != nil:
    section.add "X-Amz-Content-Sha256", valid_601451
  var valid_601452 = header.getOrDefault("X-Amz-Algorithm")
  valid_601452 = validateParameter(valid_601452, JString, required = false,
                                 default = nil)
  if valid_601452 != nil:
    section.add "X-Amz-Algorithm", valid_601452
  var valid_601453 = header.getOrDefault("X-Amz-Signature")
  valid_601453 = validateParameter(valid_601453, JString, required = false,
                                 default = nil)
  if valid_601453 != nil:
    section.add "X-Amz-Signature", valid_601453
  var valid_601454 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601454 = validateParameter(valid_601454, JString, required = false,
                                 default = nil)
  if valid_601454 != nil:
    section.add "X-Amz-SignedHeaders", valid_601454
  var valid_601455 = header.getOrDefault("X-Amz-Credential")
  valid_601455 = validateParameter(valid_601455, JString, required = false,
                                 default = nil)
  if valid_601455 != nil:
    section.add "X-Amz-Credential", valid_601455
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601456: Call_GetDescribeStemmingOptions_601443; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the stemming dictionary configured for the search domain.
  ## 
  let valid = call_601456.validator(path, query, header, formData, body)
  let scheme = call_601456.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601456.url(scheme.get, call_601456.host, call_601456.base,
                         call_601456.route, valid.getOrDefault("path"))
  result = hook(call_601456, url, valid)

proc call*(call_601457: Call_GetDescribeStemmingOptions_601443; DomainName: string;
          Action: string = "DescribeStemmingOptions"; Version: string = "2011-02-01"): Recallable =
  ## getDescribeStemmingOptions
  ## Gets the stemming dictionary configured for the search domain.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_601458 = newJObject()
  add(query_601458, "Action", newJString(Action))
  add(query_601458, "DomainName", newJString(DomainName))
  add(query_601458, "Version", newJString(Version))
  result = call_601457.call(nil, query_601458, nil, nil, nil)

var getDescribeStemmingOptions* = Call_GetDescribeStemmingOptions_601443(
    name: "getDescribeStemmingOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeStemmingOptions",
    validator: validate_GetDescribeStemmingOptions_601444, base: "/",
    url: url_GetDescribeStemmingOptions_601445,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeStopwordOptions_601492 = ref object of OpenApiRestCall_600426
proc url_PostDescribeStopwordOptions_601494(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeStopwordOptions_601493(path: JsonNode; query: JsonNode;
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
  var valid_601495 = query.getOrDefault("Action")
  valid_601495 = validateParameter(valid_601495, JString, required = true, default = newJString(
      "DescribeStopwordOptions"))
  if valid_601495 != nil:
    section.add "Action", valid_601495
  var valid_601496 = query.getOrDefault("Version")
  valid_601496 = validateParameter(valid_601496, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_601496 != nil:
    section.add "Version", valid_601496
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
  var valid_601497 = header.getOrDefault("X-Amz-Date")
  valid_601497 = validateParameter(valid_601497, JString, required = false,
                                 default = nil)
  if valid_601497 != nil:
    section.add "X-Amz-Date", valid_601497
  var valid_601498 = header.getOrDefault("X-Amz-Security-Token")
  valid_601498 = validateParameter(valid_601498, JString, required = false,
                                 default = nil)
  if valid_601498 != nil:
    section.add "X-Amz-Security-Token", valid_601498
  var valid_601499 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601499 = validateParameter(valid_601499, JString, required = false,
                                 default = nil)
  if valid_601499 != nil:
    section.add "X-Amz-Content-Sha256", valid_601499
  var valid_601500 = header.getOrDefault("X-Amz-Algorithm")
  valid_601500 = validateParameter(valid_601500, JString, required = false,
                                 default = nil)
  if valid_601500 != nil:
    section.add "X-Amz-Algorithm", valid_601500
  var valid_601501 = header.getOrDefault("X-Amz-Signature")
  valid_601501 = validateParameter(valid_601501, JString, required = false,
                                 default = nil)
  if valid_601501 != nil:
    section.add "X-Amz-Signature", valid_601501
  var valid_601502 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601502 = validateParameter(valid_601502, JString, required = false,
                                 default = nil)
  if valid_601502 != nil:
    section.add "X-Amz-SignedHeaders", valid_601502
  var valid_601503 = header.getOrDefault("X-Amz-Credential")
  valid_601503 = validateParameter(valid_601503, JString, required = false,
                                 default = nil)
  if valid_601503 != nil:
    section.add "X-Amz-Credential", valid_601503
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_601504 = formData.getOrDefault("DomainName")
  valid_601504 = validateParameter(valid_601504, JString, required = true,
                                 default = nil)
  if valid_601504 != nil:
    section.add "DomainName", valid_601504
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601505: Call_PostDescribeStopwordOptions_601492; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the stopwords configured for the search domain.
  ## 
  let valid = call_601505.validator(path, query, header, formData, body)
  let scheme = call_601505.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601505.url(scheme.get, call_601505.host, call_601505.base,
                         call_601505.route, valid.getOrDefault("path"))
  result = hook(call_601505, url, valid)

proc call*(call_601506: Call_PostDescribeStopwordOptions_601492;
          DomainName: string; Action: string = "DescribeStopwordOptions";
          Version: string = "2011-02-01"): Recallable =
  ## postDescribeStopwordOptions
  ## Gets the stopwords configured for the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601507 = newJObject()
  var formData_601508 = newJObject()
  add(formData_601508, "DomainName", newJString(DomainName))
  add(query_601507, "Action", newJString(Action))
  add(query_601507, "Version", newJString(Version))
  result = call_601506.call(nil, query_601507, nil, formData_601508, nil)

var postDescribeStopwordOptions* = Call_PostDescribeStopwordOptions_601492(
    name: "postDescribeStopwordOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeStopwordOptions",
    validator: validate_PostDescribeStopwordOptions_601493, base: "/",
    url: url_PostDescribeStopwordOptions_601494,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeStopwordOptions_601476 = ref object of OpenApiRestCall_600426
proc url_GetDescribeStopwordOptions_601478(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeStopwordOptions_601477(path: JsonNode; query: JsonNode;
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
  var valid_601479 = query.getOrDefault("Action")
  valid_601479 = validateParameter(valid_601479, JString, required = true, default = newJString(
      "DescribeStopwordOptions"))
  if valid_601479 != nil:
    section.add "Action", valid_601479
  var valid_601480 = query.getOrDefault("DomainName")
  valid_601480 = validateParameter(valid_601480, JString, required = true,
                                 default = nil)
  if valid_601480 != nil:
    section.add "DomainName", valid_601480
  var valid_601481 = query.getOrDefault("Version")
  valid_601481 = validateParameter(valid_601481, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_601481 != nil:
    section.add "Version", valid_601481
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
  var valid_601482 = header.getOrDefault("X-Amz-Date")
  valid_601482 = validateParameter(valid_601482, JString, required = false,
                                 default = nil)
  if valid_601482 != nil:
    section.add "X-Amz-Date", valid_601482
  var valid_601483 = header.getOrDefault("X-Amz-Security-Token")
  valid_601483 = validateParameter(valid_601483, JString, required = false,
                                 default = nil)
  if valid_601483 != nil:
    section.add "X-Amz-Security-Token", valid_601483
  var valid_601484 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601484 = validateParameter(valid_601484, JString, required = false,
                                 default = nil)
  if valid_601484 != nil:
    section.add "X-Amz-Content-Sha256", valid_601484
  var valid_601485 = header.getOrDefault("X-Amz-Algorithm")
  valid_601485 = validateParameter(valid_601485, JString, required = false,
                                 default = nil)
  if valid_601485 != nil:
    section.add "X-Amz-Algorithm", valid_601485
  var valid_601486 = header.getOrDefault("X-Amz-Signature")
  valid_601486 = validateParameter(valid_601486, JString, required = false,
                                 default = nil)
  if valid_601486 != nil:
    section.add "X-Amz-Signature", valid_601486
  var valid_601487 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601487 = validateParameter(valid_601487, JString, required = false,
                                 default = nil)
  if valid_601487 != nil:
    section.add "X-Amz-SignedHeaders", valid_601487
  var valid_601488 = header.getOrDefault("X-Amz-Credential")
  valid_601488 = validateParameter(valid_601488, JString, required = false,
                                 default = nil)
  if valid_601488 != nil:
    section.add "X-Amz-Credential", valid_601488
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601489: Call_GetDescribeStopwordOptions_601476; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the stopwords configured for the search domain.
  ## 
  let valid = call_601489.validator(path, query, header, formData, body)
  let scheme = call_601489.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601489.url(scheme.get, call_601489.host, call_601489.base,
                         call_601489.route, valid.getOrDefault("path"))
  result = hook(call_601489, url, valid)

proc call*(call_601490: Call_GetDescribeStopwordOptions_601476; DomainName: string;
          Action: string = "DescribeStopwordOptions"; Version: string = "2011-02-01"): Recallable =
  ## getDescribeStopwordOptions
  ## Gets the stopwords configured for the search domain.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_601491 = newJObject()
  add(query_601491, "Action", newJString(Action))
  add(query_601491, "DomainName", newJString(DomainName))
  add(query_601491, "Version", newJString(Version))
  result = call_601490.call(nil, query_601491, nil, nil, nil)

var getDescribeStopwordOptions* = Call_GetDescribeStopwordOptions_601476(
    name: "getDescribeStopwordOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeStopwordOptions",
    validator: validate_GetDescribeStopwordOptions_601477, base: "/",
    url: url_GetDescribeStopwordOptions_601478,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeSynonymOptions_601525 = ref object of OpenApiRestCall_600426
proc url_PostDescribeSynonymOptions_601527(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostDescribeSynonymOptions_601526(path: JsonNode; query: JsonNode;
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
  var valid_601528 = query.getOrDefault("Action")
  valid_601528 = validateParameter(valid_601528, JString, required = true,
                                 default = newJString("DescribeSynonymOptions"))
  if valid_601528 != nil:
    section.add "Action", valid_601528
  var valid_601529 = query.getOrDefault("Version")
  valid_601529 = validateParameter(valid_601529, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_601529 != nil:
    section.add "Version", valid_601529
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
  var valid_601530 = header.getOrDefault("X-Amz-Date")
  valid_601530 = validateParameter(valid_601530, JString, required = false,
                                 default = nil)
  if valid_601530 != nil:
    section.add "X-Amz-Date", valid_601530
  var valid_601531 = header.getOrDefault("X-Amz-Security-Token")
  valid_601531 = validateParameter(valid_601531, JString, required = false,
                                 default = nil)
  if valid_601531 != nil:
    section.add "X-Amz-Security-Token", valid_601531
  var valid_601532 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601532 = validateParameter(valid_601532, JString, required = false,
                                 default = nil)
  if valid_601532 != nil:
    section.add "X-Amz-Content-Sha256", valid_601532
  var valid_601533 = header.getOrDefault("X-Amz-Algorithm")
  valid_601533 = validateParameter(valid_601533, JString, required = false,
                                 default = nil)
  if valid_601533 != nil:
    section.add "X-Amz-Algorithm", valid_601533
  var valid_601534 = header.getOrDefault("X-Amz-Signature")
  valid_601534 = validateParameter(valid_601534, JString, required = false,
                                 default = nil)
  if valid_601534 != nil:
    section.add "X-Amz-Signature", valid_601534
  var valid_601535 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601535 = validateParameter(valid_601535, JString, required = false,
                                 default = nil)
  if valid_601535 != nil:
    section.add "X-Amz-SignedHeaders", valid_601535
  var valid_601536 = header.getOrDefault("X-Amz-Credential")
  valid_601536 = validateParameter(valid_601536, JString, required = false,
                                 default = nil)
  if valid_601536 != nil:
    section.add "X-Amz-Credential", valid_601536
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_601537 = formData.getOrDefault("DomainName")
  valid_601537 = validateParameter(valid_601537, JString, required = true,
                                 default = nil)
  if valid_601537 != nil:
    section.add "DomainName", valid_601537
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601538: Call_PostDescribeSynonymOptions_601525; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the synonym dictionary configured for the search domain.
  ## 
  let valid = call_601538.validator(path, query, header, formData, body)
  let scheme = call_601538.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601538.url(scheme.get, call_601538.host, call_601538.base,
                         call_601538.route, valid.getOrDefault("path"))
  result = hook(call_601538, url, valid)

proc call*(call_601539: Call_PostDescribeSynonymOptions_601525; DomainName: string;
          Action: string = "DescribeSynonymOptions"; Version: string = "2011-02-01"): Recallable =
  ## postDescribeSynonymOptions
  ## Gets the synonym dictionary configured for the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601540 = newJObject()
  var formData_601541 = newJObject()
  add(formData_601541, "DomainName", newJString(DomainName))
  add(query_601540, "Action", newJString(Action))
  add(query_601540, "Version", newJString(Version))
  result = call_601539.call(nil, query_601540, nil, formData_601541, nil)

var postDescribeSynonymOptions* = Call_PostDescribeSynonymOptions_601525(
    name: "postDescribeSynonymOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeSynonymOptions",
    validator: validate_PostDescribeSynonymOptions_601526, base: "/",
    url: url_PostDescribeSynonymOptions_601527,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeSynonymOptions_601509 = ref object of OpenApiRestCall_600426
proc url_GetDescribeSynonymOptions_601511(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetDescribeSynonymOptions_601510(path: JsonNode; query: JsonNode;
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
  var valid_601512 = query.getOrDefault("Action")
  valid_601512 = validateParameter(valid_601512, JString, required = true,
                                 default = newJString("DescribeSynonymOptions"))
  if valid_601512 != nil:
    section.add "Action", valid_601512
  var valid_601513 = query.getOrDefault("DomainName")
  valid_601513 = validateParameter(valid_601513, JString, required = true,
                                 default = nil)
  if valid_601513 != nil:
    section.add "DomainName", valid_601513
  var valid_601514 = query.getOrDefault("Version")
  valid_601514 = validateParameter(valid_601514, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_601514 != nil:
    section.add "Version", valid_601514
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
  var valid_601515 = header.getOrDefault("X-Amz-Date")
  valid_601515 = validateParameter(valid_601515, JString, required = false,
                                 default = nil)
  if valid_601515 != nil:
    section.add "X-Amz-Date", valid_601515
  var valid_601516 = header.getOrDefault("X-Amz-Security-Token")
  valid_601516 = validateParameter(valid_601516, JString, required = false,
                                 default = nil)
  if valid_601516 != nil:
    section.add "X-Amz-Security-Token", valid_601516
  var valid_601517 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601517 = validateParameter(valid_601517, JString, required = false,
                                 default = nil)
  if valid_601517 != nil:
    section.add "X-Amz-Content-Sha256", valid_601517
  var valid_601518 = header.getOrDefault("X-Amz-Algorithm")
  valid_601518 = validateParameter(valid_601518, JString, required = false,
                                 default = nil)
  if valid_601518 != nil:
    section.add "X-Amz-Algorithm", valid_601518
  var valid_601519 = header.getOrDefault("X-Amz-Signature")
  valid_601519 = validateParameter(valid_601519, JString, required = false,
                                 default = nil)
  if valid_601519 != nil:
    section.add "X-Amz-Signature", valid_601519
  var valid_601520 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601520 = validateParameter(valid_601520, JString, required = false,
                                 default = nil)
  if valid_601520 != nil:
    section.add "X-Amz-SignedHeaders", valid_601520
  var valid_601521 = header.getOrDefault("X-Amz-Credential")
  valid_601521 = validateParameter(valid_601521, JString, required = false,
                                 default = nil)
  if valid_601521 != nil:
    section.add "X-Amz-Credential", valid_601521
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601522: Call_GetDescribeSynonymOptions_601509; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the synonym dictionary configured for the search domain.
  ## 
  let valid = call_601522.validator(path, query, header, formData, body)
  let scheme = call_601522.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601522.url(scheme.get, call_601522.host, call_601522.base,
                         call_601522.route, valid.getOrDefault("path"))
  result = hook(call_601522, url, valid)

proc call*(call_601523: Call_GetDescribeSynonymOptions_601509; DomainName: string;
          Action: string = "DescribeSynonymOptions"; Version: string = "2011-02-01"): Recallable =
  ## getDescribeSynonymOptions
  ## Gets the synonym dictionary configured for the search domain.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_601524 = newJObject()
  add(query_601524, "Action", newJString(Action))
  add(query_601524, "DomainName", newJString(DomainName))
  add(query_601524, "Version", newJString(Version))
  result = call_601523.call(nil, query_601524, nil, nil, nil)

var getDescribeSynonymOptions* = Call_GetDescribeSynonymOptions_601509(
    name: "getDescribeSynonymOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeSynonymOptions",
    validator: validate_GetDescribeSynonymOptions_601510, base: "/",
    url: url_GetDescribeSynonymOptions_601511,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostIndexDocuments_601558 = ref object of OpenApiRestCall_600426
proc url_PostIndexDocuments_601560(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostIndexDocuments_601559(path: JsonNode; query: JsonNode;
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
  var valid_601561 = query.getOrDefault("Action")
  valid_601561 = validateParameter(valid_601561, JString, required = true,
                                 default = newJString("IndexDocuments"))
  if valid_601561 != nil:
    section.add "Action", valid_601561
  var valid_601562 = query.getOrDefault("Version")
  valid_601562 = validateParameter(valid_601562, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_601562 != nil:
    section.add "Version", valid_601562
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
  var valid_601563 = header.getOrDefault("X-Amz-Date")
  valid_601563 = validateParameter(valid_601563, JString, required = false,
                                 default = nil)
  if valid_601563 != nil:
    section.add "X-Amz-Date", valid_601563
  var valid_601564 = header.getOrDefault("X-Amz-Security-Token")
  valid_601564 = validateParameter(valid_601564, JString, required = false,
                                 default = nil)
  if valid_601564 != nil:
    section.add "X-Amz-Security-Token", valid_601564
  var valid_601565 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601565 = validateParameter(valid_601565, JString, required = false,
                                 default = nil)
  if valid_601565 != nil:
    section.add "X-Amz-Content-Sha256", valid_601565
  var valid_601566 = header.getOrDefault("X-Amz-Algorithm")
  valid_601566 = validateParameter(valid_601566, JString, required = false,
                                 default = nil)
  if valid_601566 != nil:
    section.add "X-Amz-Algorithm", valid_601566
  var valid_601567 = header.getOrDefault("X-Amz-Signature")
  valid_601567 = validateParameter(valid_601567, JString, required = false,
                                 default = nil)
  if valid_601567 != nil:
    section.add "X-Amz-Signature", valid_601567
  var valid_601568 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601568 = validateParameter(valid_601568, JString, required = false,
                                 default = nil)
  if valid_601568 != nil:
    section.add "X-Amz-SignedHeaders", valid_601568
  var valid_601569 = header.getOrDefault("X-Amz-Credential")
  valid_601569 = validateParameter(valid_601569, JString, required = false,
                                 default = nil)
  if valid_601569 != nil:
    section.add "X-Amz-Credential", valid_601569
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_601570 = formData.getOrDefault("DomainName")
  valid_601570 = validateParameter(valid_601570, JString, required = true,
                                 default = nil)
  if valid_601570 != nil:
    section.add "DomainName", valid_601570
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601571: Call_PostIndexDocuments_601558; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Tells the search domain to start indexing its documents using the latest text processing options and <code>IndexFields</code>. This operation must be invoked to make options whose <a>OptionStatus</a> has <code>OptionState</code> of <code>RequiresIndexDocuments</code> visible in search results.
  ## 
  let valid = call_601571.validator(path, query, header, formData, body)
  let scheme = call_601571.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601571.url(scheme.get, call_601571.host, call_601571.base,
                         call_601571.route, valid.getOrDefault("path"))
  result = hook(call_601571, url, valid)

proc call*(call_601572: Call_PostIndexDocuments_601558; DomainName: string;
          Action: string = "IndexDocuments"; Version: string = "2011-02-01"): Recallable =
  ## postIndexDocuments
  ## Tells the search domain to start indexing its documents using the latest text processing options and <code>IndexFields</code>. This operation must be invoked to make options whose <a>OptionStatus</a> has <code>OptionState</code> of <code>RequiresIndexDocuments</code> visible in search results.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_601573 = newJObject()
  var formData_601574 = newJObject()
  add(formData_601574, "DomainName", newJString(DomainName))
  add(query_601573, "Action", newJString(Action))
  add(query_601573, "Version", newJString(Version))
  result = call_601572.call(nil, query_601573, nil, formData_601574, nil)

var postIndexDocuments* = Call_PostIndexDocuments_601558(
    name: "postIndexDocuments", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=IndexDocuments",
    validator: validate_PostIndexDocuments_601559, base: "/",
    url: url_PostIndexDocuments_601560, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIndexDocuments_601542 = ref object of OpenApiRestCall_600426
proc url_GetIndexDocuments_601544(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetIndexDocuments_601543(path: JsonNode; query: JsonNode;
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
  var valid_601545 = query.getOrDefault("Action")
  valid_601545 = validateParameter(valid_601545, JString, required = true,
                                 default = newJString("IndexDocuments"))
  if valid_601545 != nil:
    section.add "Action", valid_601545
  var valid_601546 = query.getOrDefault("DomainName")
  valid_601546 = validateParameter(valid_601546, JString, required = true,
                                 default = nil)
  if valid_601546 != nil:
    section.add "DomainName", valid_601546
  var valid_601547 = query.getOrDefault("Version")
  valid_601547 = validateParameter(valid_601547, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_601547 != nil:
    section.add "Version", valid_601547
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
  var valid_601548 = header.getOrDefault("X-Amz-Date")
  valid_601548 = validateParameter(valid_601548, JString, required = false,
                                 default = nil)
  if valid_601548 != nil:
    section.add "X-Amz-Date", valid_601548
  var valid_601549 = header.getOrDefault("X-Amz-Security-Token")
  valid_601549 = validateParameter(valid_601549, JString, required = false,
                                 default = nil)
  if valid_601549 != nil:
    section.add "X-Amz-Security-Token", valid_601549
  var valid_601550 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601550 = validateParameter(valid_601550, JString, required = false,
                                 default = nil)
  if valid_601550 != nil:
    section.add "X-Amz-Content-Sha256", valid_601550
  var valid_601551 = header.getOrDefault("X-Amz-Algorithm")
  valid_601551 = validateParameter(valid_601551, JString, required = false,
                                 default = nil)
  if valid_601551 != nil:
    section.add "X-Amz-Algorithm", valid_601551
  var valid_601552 = header.getOrDefault("X-Amz-Signature")
  valid_601552 = validateParameter(valid_601552, JString, required = false,
                                 default = nil)
  if valid_601552 != nil:
    section.add "X-Amz-Signature", valid_601552
  var valid_601553 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601553 = validateParameter(valid_601553, JString, required = false,
                                 default = nil)
  if valid_601553 != nil:
    section.add "X-Amz-SignedHeaders", valid_601553
  var valid_601554 = header.getOrDefault("X-Amz-Credential")
  valid_601554 = validateParameter(valid_601554, JString, required = false,
                                 default = nil)
  if valid_601554 != nil:
    section.add "X-Amz-Credential", valid_601554
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601555: Call_GetIndexDocuments_601542; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Tells the search domain to start indexing its documents using the latest text processing options and <code>IndexFields</code>. This operation must be invoked to make options whose <a>OptionStatus</a> has <code>OptionState</code> of <code>RequiresIndexDocuments</code> visible in search results.
  ## 
  let valid = call_601555.validator(path, query, header, formData, body)
  let scheme = call_601555.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601555.url(scheme.get, call_601555.host, call_601555.base,
                         call_601555.route, valid.getOrDefault("path"))
  result = hook(call_601555, url, valid)

proc call*(call_601556: Call_GetIndexDocuments_601542; DomainName: string;
          Action: string = "IndexDocuments"; Version: string = "2011-02-01"): Recallable =
  ## getIndexDocuments
  ## Tells the search domain to start indexing its documents using the latest text processing options and <code>IndexFields</code>. This operation must be invoked to make options whose <a>OptionStatus</a> has <code>OptionState</code> of <code>RequiresIndexDocuments</code> visible in search results.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_601557 = newJObject()
  add(query_601557, "Action", newJString(Action))
  add(query_601557, "DomainName", newJString(DomainName))
  add(query_601557, "Version", newJString(Version))
  result = call_601556.call(nil, query_601557, nil, nil, nil)

var getIndexDocuments* = Call_GetIndexDocuments_601542(name: "getIndexDocuments",
    meth: HttpMethod.HttpGet, host: "cloudsearch.amazonaws.com",
    route: "/#Action=IndexDocuments", validator: validate_GetIndexDocuments_601543,
    base: "/", url: url_GetIndexDocuments_601544,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateAvailabilityOptions_601592 = ref object of OpenApiRestCall_600426
proc url_PostUpdateAvailabilityOptions_601594(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostUpdateAvailabilityOptions_601593(path: JsonNode; query: JsonNode;
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
  var valid_601595 = query.getOrDefault("Action")
  valid_601595 = validateParameter(valid_601595, JString, required = true, default = newJString(
      "UpdateAvailabilityOptions"))
  if valid_601595 != nil:
    section.add "Action", valid_601595
  var valid_601596 = query.getOrDefault("Version")
  valid_601596 = validateParameter(valid_601596, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_601596 != nil:
    section.add "Version", valid_601596
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
  var valid_601597 = header.getOrDefault("X-Amz-Date")
  valid_601597 = validateParameter(valid_601597, JString, required = false,
                                 default = nil)
  if valid_601597 != nil:
    section.add "X-Amz-Date", valid_601597
  var valid_601598 = header.getOrDefault("X-Amz-Security-Token")
  valid_601598 = validateParameter(valid_601598, JString, required = false,
                                 default = nil)
  if valid_601598 != nil:
    section.add "X-Amz-Security-Token", valid_601598
  var valid_601599 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601599 = validateParameter(valid_601599, JString, required = false,
                                 default = nil)
  if valid_601599 != nil:
    section.add "X-Amz-Content-Sha256", valid_601599
  var valid_601600 = header.getOrDefault("X-Amz-Algorithm")
  valid_601600 = validateParameter(valid_601600, JString, required = false,
                                 default = nil)
  if valid_601600 != nil:
    section.add "X-Amz-Algorithm", valid_601600
  var valid_601601 = header.getOrDefault("X-Amz-Signature")
  valid_601601 = validateParameter(valid_601601, JString, required = false,
                                 default = nil)
  if valid_601601 != nil:
    section.add "X-Amz-Signature", valid_601601
  var valid_601602 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601602 = validateParameter(valid_601602, JString, required = false,
                                 default = nil)
  if valid_601602 != nil:
    section.add "X-Amz-SignedHeaders", valid_601602
  var valid_601603 = header.getOrDefault("X-Amz-Credential")
  valid_601603 = validateParameter(valid_601603, JString, required = false,
                                 default = nil)
  if valid_601603 != nil:
    section.add "X-Amz-Credential", valid_601603
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   MultiAZ: JBool (required)
  ##          : You expand an existing search domain to a second Availability Zone by setting the Multi-AZ option to true. Similarly, you can turn off the Multi-AZ option to downgrade the domain to a single Availability Zone by setting the Multi-AZ option to <code>false</code>. 
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_601604 = formData.getOrDefault("DomainName")
  valid_601604 = validateParameter(valid_601604, JString, required = true,
                                 default = nil)
  if valid_601604 != nil:
    section.add "DomainName", valid_601604
  var valid_601605 = formData.getOrDefault("MultiAZ")
  valid_601605 = validateParameter(valid_601605, JBool, required = true, default = nil)
  if valid_601605 != nil:
    section.add "MultiAZ", valid_601605
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601606: Call_PostUpdateAvailabilityOptions_601592; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_601606.validator(path, query, header, formData, body)
  let scheme = call_601606.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601606.url(scheme.get, call_601606.host, call_601606.base,
                         call_601606.route, valid.getOrDefault("path"))
  result = hook(call_601606, url, valid)

proc call*(call_601607: Call_PostUpdateAvailabilityOptions_601592;
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
  var query_601608 = newJObject()
  var formData_601609 = newJObject()
  add(formData_601609, "DomainName", newJString(DomainName))
  add(formData_601609, "MultiAZ", newJBool(MultiAZ))
  add(query_601608, "Action", newJString(Action))
  add(query_601608, "Version", newJString(Version))
  result = call_601607.call(nil, query_601608, nil, formData_601609, nil)

var postUpdateAvailabilityOptions* = Call_PostUpdateAvailabilityOptions_601592(
    name: "postUpdateAvailabilityOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateAvailabilityOptions",
    validator: validate_PostUpdateAvailabilityOptions_601593, base: "/",
    url: url_PostUpdateAvailabilityOptions_601594,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateAvailabilityOptions_601575 = ref object of OpenApiRestCall_600426
proc url_GetUpdateAvailabilityOptions_601577(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetUpdateAvailabilityOptions_601576(path: JsonNode; query: JsonNode;
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
  var valid_601578 = query.getOrDefault("MultiAZ")
  valid_601578 = validateParameter(valid_601578, JBool, required = true, default = nil)
  if valid_601578 != nil:
    section.add "MultiAZ", valid_601578
  var valid_601579 = query.getOrDefault("Action")
  valid_601579 = validateParameter(valid_601579, JString, required = true, default = newJString(
      "UpdateAvailabilityOptions"))
  if valid_601579 != nil:
    section.add "Action", valid_601579
  var valid_601580 = query.getOrDefault("DomainName")
  valid_601580 = validateParameter(valid_601580, JString, required = true,
                                 default = nil)
  if valid_601580 != nil:
    section.add "DomainName", valid_601580
  var valid_601581 = query.getOrDefault("Version")
  valid_601581 = validateParameter(valid_601581, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_601581 != nil:
    section.add "Version", valid_601581
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
  var valid_601582 = header.getOrDefault("X-Amz-Date")
  valid_601582 = validateParameter(valid_601582, JString, required = false,
                                 default = nil)
  if valid_601582 != nil:
    section.add "X-Amz-Date", valid_601582
  var valid_601583 = header.getOrDefault("X-Amz-Security-Token")
  valid_601583 = validateParameter(valid_601583, JString, required = false,
                                 default = nil)
  if valid_601583 != nil:
    section.add "X-Amz-Security-Token", valid_601583
  var valid_601584 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601584 = validateParameter(valid_601584, JString, required = false,
                                 default = nil)
  if valid_601584 != nil:
    section.add "X-Amz-Content-Sha256", valid_601584
  var valid_601585 = header.getOrDefault("X-Amz-Algorithm")
  valid_601585 = validateParameter(valid_601585, JString, required = false,
                                 default = nil)
  if valid_601585 != nil:
    section.add "X-Amz-Algorithm", valid_601585
  var valid_601586 = header.getOrDefault("X-Amz-Signature")
  valid_601586 = validateParameter(valid_601586, JString, required = false,
                                 default = nil)
  if valid_601586 != nil:
    section.add "X-Amz-Signature", valid_601586
  var valid_601587 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601587 = validateParameter(valid_601587, JString, required = false,
                                 default = nil)
  if valid_601587 != nil:
    section.add "X-Amz-SignedHeaders", valid_601587
  var valid_601588 = header.getOrDefault("X-Amz-Credential")
  valid_601588 = validateParameter(valid_601588, JString, required = false,
                                 default = nil)
  if valid_601588 != nil:
    section.add "X-Amz-Credential", valid_601588
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601589: Call_GetUpdateAvailabilityOptions_601575; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_601589.validator(path, query, header, formData, body)
  let scheme = call_601589.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601589.url(scheme.get, call_601589.host, call_601589.base,
                         call_601589.route, valid.getOrDefault("path"))
  result = hook(call_601589, url, valid)

proc call*(call_601590: Call_GetUpdateAvailabilityOptions_601575; MultiAZ: bool;
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
  var query_601591 = newJObject()
  add(query_601591, "MultiAZ", newJBool(MultiAZ))
  add(query_601591, "Action", newJString(Action))
  add(query_601591, "DomainName", newJString(DomainName))
  add(query_601591, "Version", newJString(Version))
  result = call_601590.call(nil, query_601591, nil, nil, nil)

var getUpdateAvailabilityOptions* = Call_GetUpdateAvailabilityOptions_601575(
    name: "getUpdateAvailabilityOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateAvailabilityOptions",
    validator: validate_GetUpdateAvailabilityOptions_601576, base: "/",
    url: url_GetUpdateAvailabilityOptions_601577,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateDefaultSearchField_601627 = ref object of OpenApiRestCall_600426
proc url_PostUpdateDefaultSearchField_601629(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostUpdateDefaultSearchField_601628(path: JsonNode; query: JsonNode;
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
  var valid_601630 = query.getOrDefault("Action")
  valid_601630 = validateParameter(valid_601630, JString, required = true, default = newJString(
      "UpdateDefaultSearchField"))
  if valid_601630 != nil:
    section.add "Action", valid_601630
  var valid_601631 = query.getOrDefault("Version")
  valid_601631 = validateParameter(valid_601631, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_601631 != nil:
    section.add "Version", valid_601631
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
  var valid_601632 = header.getOrDefault("X-Amz-Date")
  valid_601632 = validateParameter(valid_601632, JString, required = false,
                                 default = nil)
  if valid_601632 != nil:
    section.add "X-Amz-Date", valid_601632
  var valid_601633 = header.getOrDefault("X-Amz-Security-Token")
  valid_601633 = validateParameter(valid_601633, JString, required = false,
                                 default = nil)
  if valid_601633 != nil:
    section.add "X-Amz-Security-Token", valid_601633
  var valid_601634 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601634 = validateParameter(valid_601634, JString, required = false,
                                 default = nil)
  if valid_601634 != nil:
    section.add "X-Amz-Content-Sha256", valid_601634
  var valid_601635 = header.getOrDefault("X-Amz-Algorithm")
  valid_601635 = validateParameter(valid_601635, JString, required = false,
                                 default = nil)
  if valid_601635 != nil:
    section.add "X-Amz-Algorithm", valid_601635
  var valid_601636 = header.getOrDefault("X-Amz-Signature")
  valid_601636 = validateParameter(valid_601636, JString, required = false,
                                 default = nil)
  if valid_601636 != nil:
    section.add "X-Amz-Signature", valid_601636
  var valid_601637 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601637 = validateParameter(valid_601637, JString, required = false,
                                 default = nil)
  if valid_601637 != nil:
    section.add "X-Amz-SignedHeaders", valid_601637
  var valid_601638 = header.getOrDefault("X-Amz-Credential")
  valid_601638 = validateParameter(valid_601638, JString, required = false,
                                 default = nil)
  if valid_601638 != nil:
    section.add "X-Amz-Credential", valid_601638
  result.add "header", section
  ## parameters in `formData` object:
  ##   DefaultSearchField: JString (required)
  ##                     : The text field to search if the search request does not specify which field to search. The default search field is used when search terms are specified with the <code>q</code> parameter, or if a match expression specified with the <code>bq</code> parameter does not constrain the search to a particular field. The default is an empty string, which automatically searches all text fields.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DefaultSearchField` field"
  var valid_601639 = formData.getOrDefault("DefaultSearchField")
  valid_601639 = validateParameter(valid_601639, JString, required = true,
                                 default = nil)
  if valid_601639 != nil:
    section.add "DefaultSearchField", valid_601639
  var valid_601640 = formData.getOrDefault("DomainName")
  valid_601640 = validateParameter(valid_601640, JString, required = true,
                                 default = nil)
  if valid_601640 != nil:
    section.add "DomainName", valid_601640
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601641: Call_PostUpdateDefaultSearchField_601627; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the default search field for the search domain. The default search field is the text field that is searched when a search request does not specify which fields to search. By default, it is configured to include the contents of all of the domain's text fields. 
  ## 
  let valid = call_601641.validator(path, query, header, formData, body)
  let scheme = call_601641.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601641.url(scheme.get, call_601641.host, call_601641.base,
                         call_601641.route, valid.getOrDefault("path"))
  result = hook(call_601641, url, valid)

proc call*(call_601642: Call_PostUpdateDefaultSearchField_601627;
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
  var query_601643 = newJObject()
  var formData_601644 = newJObject()
  add(formData_601644, "DefaultSearchField", newJString(DefaultSearchField))
  add(formData_601644, "DomainName", newJString(DomainName))
  add(query_601643, "Action", newJString(Action))
  add(query_601643, "Version", newJString(Version))
  result = call_601642.call(nil, query_601643, nil, formData_601644, nil)

var postUpdateDefaultSearchField* = Call_PostUpdateDefaultSearchField_601627(
    name: "postUpdateDefaultSearchField", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateDefaultSearchField",
    validator: validate_PostUpdateDefaultSearchField_601628, base: "/",
    url: url_PostUpdateDefaultSearchField_601629,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateDefaultSearchField_601610 = ref object of OpenApiRestCall_600426
proc url_GetUpdateDefaultSearchField_601612(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetUpdateDefaultSearchField_601611(path: JsonNode; query: JsonNode;
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
  var valid_601613 = query.getOrDefault("Action")
  valid_601613 = validateParameter(valid_601613, JString, required = true, default = newJString(
      "UpdateDefaultSearchField"))
  if valid_601613 != nil:
    section.add "Action", valid_601613
  var valid_601614 = query.getOrDefault("DomainName")
  valid_601614 = validateParameter(valid_601614, JString, required = true,
                                 default = nil)
  if valid_601614 != nil:
    section.add "DomainName", valid_601614
  var valid_601615 = query.getOrDefault("DefaultSearchField")
  valid_601615 = validateParameter(valid_601615, JString, required = true,
                                 default = nil)
  if valid_601615 != nil:
    section.add "DefaultSearchField", valid_601615
  var valid_601616 = query.getOrDefault("Version")
  valid_601616 = validateParameter(valid_601616, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_601616 != nil:
    section.add "Version", valid_601616
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
  var valid_601617 = header.getOrDefault("X-Amz-Date")
  valid_601617 = validateParameter(valid_601617, JString, required = false,
                                 default = nil)
  if valid_601617 != nil:
    section.add "X-Amz-Date", valid_601617
  var valid_601618 = header.getOrDefault("X-Amz-Security-Token")
  valid_601618 = validateParameter(valid_601618, JString, required = false,
                                 default = nil)
  if valid_601618 != nil:
    section.add "X-Amz-Security-Token", valid_601618
  var valid_601619 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601619 = validateParameter(valid_601619, JString, required = false,
                                 default = nil)
  if valid_601619 != nil:
    section.add "X-Amz-Content-Sha256", valid_601619
  var valid_601620 = header.getOrDefault("X-Amz-Algorithm")
  valid_601620 = validateParameter(valid_601620, JString, required = false,
                                 default = nil)
  if valid_601620 != nil:
    section.add "X-Amz-Algorithm", valid_601620
  var valid_601621 = header.getOrDefault("X-Amz-Signature")
  valid_601621 = validateParameter(valid_601621, JString, required = false,
                                 default = nil)
  if valid_601621 != nil:
    section.add "X-Amz-Signature", valid_601621
  var valid_601622 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601622 = validateParameter(valid_601622, JString, required = false,
                                 default = nil)
  if valid_601622 != nil:
    section.add "X-Amz-SignedHeaders", valid_601622
  var valid_601623 = header.getOrDefault("X-Amz-Credential")
  valid_601623 = validateParameter(valid_601623, JString, required = false,
                                 default = nil)
  if valid_601623 != nil:
    section.add "X-Amz-Credential", valid_601623
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601624: Call_GetUpdateDefaultSearchField_601610; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the default search field for the search domain. The default search field is the text field that is searched when a search request does not specify which fields to search. By default, it is configured to include the contents of all of the domain's text fields. 
  ## 
  let valid = call_601624.validator(path, query, header, formData, body)
  let scheme = call_601624.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601624.url(scheme.get, call_601624.host, call_601624.base,
                         call_601624.route, valid.getOrDefault("path"))
  result = hook(call_601624, url, valid)

proc call*(call_601625: Call_GetUpdateDefaultSearchField_601610;
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
  var query_601626 = newJObject()
  add(query_601626, "Action", newJString(Action))
  add(query_601626, "DomainName", newJString(DomainName))
  add(query_601626, "DefaultSearchField", newJString(DefaultSearchField))
  add(query_601626, "Version", newJString(Version))
  result = call_601625.call(nil, query_601626, nil, nil, nil)

var getUpdateDefaultSearchField* = Call_GetUpdateDefaultSearchField_601610(
    name: "getUpdateDefaultSearchField", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateDefaultSearchField",
    validator: validate_GetUpdateDefaultSearchField_601611, base: "/",
    url: url_GetUpdateDefaultSearchField_601612,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateServiceAccessPolicies_601662 = ref object of OpenApiRestCall_600426
proc url_PostUpdateServiceAccessPolicies_601664(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostUpdateServiceAccessPolicies_601663(path: JsonNode;
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
  var valid_601665 = query.getOrDefault("Action")
  valid_601665 = validateParameter(valid_601665, JString, required = true, default = newJString(
      "UpdateServiceAccessPolicies"))
  if valid_601665 != nil:
    section.add "Action", valid_601665
  var valid_601666 = query.getOrDefault("Version")
  valid_601666 = validateParameter(valid_601666, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_601666 != nil:
    section.add "Version", valid_601666
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
  var valid_601667 = header.getOrDefault("X-Amz-Date")
  valid_601667 = validateParameter(valid_601667, JString, required = false,
                                 default = nil)
  if valid_601667 != nil:
    section.add "X-Amz-Date", valid_601667
  var valid_601668 = header.getOrDefault("X-Amz-Security-Token")
  valid_601668 = validateParameter(valid_601668, JString, required = false,
                                 default = nil)
  if valid_601668 != nil:
    section.add "X-Amz-Security-Token", valid_601668
  var valid_601669 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601669 = validateParameter(valid_601669, JString, required = false,
                                 default = nil)
  if valid_601669 != nil:
    section.add "X-Amz-Content-Sha256", valid_601669
  var valid_601670 = header.getOrDefault("X-Amz-Algorithm")
  valid_601670 = validateParameter(valid_601670, JString, required = false,
                                 default = nil)
  if valid_601670 != nil:
    section.add "X-Amz-Algorithm", valid_601670
  var valid_601671 = header.getOrDefault("X-Amz-Signature")
  valid_601671 = validateParameter(valid_601671, JString, required = false,
                                 default = nil)
  if valid_601671 != nil:
    section.add "X-Amz-Signature", valid_601671
  var valid_601672 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601672 = validateParameter(valid_601672, JString, required = false,
                                 default = nil)
  if valid_601672 != nil:
    section.add "X-Amz-SignedHeaders", valid_601672
  var valid_601673 = header.getOrDefault("X-Amz-Credential")
  valid_601673 = validateParameter(valid_601673, JString, required = false,
                                 default = nil)
  if valid_601673 != nil:
    section.add "X-Amz-Credential", valid_601673
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
  var valid_601674 = formData.getOrDefault("DomainName")
  valid_601674 = validateParameter(valid_601674, JString, required = true,
                                 default = nil)
  if valid_601674 != nil:
    section.add "DomainName", valid_601674
  var valid_601675 = formData.getOrDefault("AccessPolicies")
  valid_601675 = validateParameter(valid_601675, JString, required = true,
                                 default = nil)
  if valid_601675 != nil:
    section.add "AccessPolicies", valid_601675
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601676: Call_PostUpdateServiceAccessPolicies_601662;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Configures the policies that control access to the domain's document and search services. The maximum size of an access policy document is 100 KB.
  ## 
  let valid = call_601676.validator(path, query, header, formData, body)
  let scheme = call_601676.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601676.url(scheme.get, call_601676.host, call_601676.base,
                         call_601676.route, valid.getOrDefault("path"))
  result = hook(call_601676, url, valid)

proc call*(call_601677: Call_PostUpdateServiceAccessPolicies_601662;
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
  var query_601678 = newJObject()
  var formData_601679 = newJObject()
  add(formData_601679, "DomainName", newJString(DomainName))
  add(formData_601679, "AccessPolicies", newJString(AccessPolicies))
  add(query_601678, "Action", newJString(Action))
  add(query_601678, "Version", newJString(Version))
  result = call_601677.call(nil, query_601678, nil, formData_601679, nil)

var postUpdateServiceAccessPolicies* = Call_PostUpdateServiceAccessPolicies_601662(
    name: "postUpdateServiceAccessPolicies", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateServiceAccessPolicies",
    validator: validate_PostUpdateServiceAccessPolicies_601663, base: "/",
    url: url_PostUpdateServiceAccessPolicies_601664,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateServiceAccessPolicies_601645 = ref object of OpenApiRestCall_600426
proc url_GetUpdateServiceAccessPolicies_601647(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetUpdateServiceAccessPolicies_601646(path: JsonNode;
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
  var valid_601648 = query.getOrDefault("Action")
  valid_601648 = validateParameter(valid_601648, JString, required = true, default = newJString(
      "UpdateServiceAccessPolicies"))
  if valid_601648 != nil:
    section.add "Action", valid_601648
  var valid_601649 = query.getOrDefault("AccessPolicies")
  valid_601649 = validateParameter(valid_601649, JString, required = true,
                                 default = nil)
  if valid_601649 != nil:
    section.add "AccessPolicies", valid_601649
  var valid_601650 = query.getOrDefault("DomainName")
  valid_601650 = validateParameter(valid_601650, JString, required = true,
                                 default = nil)
  if valid_601650 != nil:
    section.add "DomainName", valid_601650
  var valid_601651 = query.getOrDefault("Version")
  valid_601651 = validateParameter(valid_601651, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_601651 != nil:
    section.add "Version", valid_601651
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
  var valid_601652 = header.getOrDefault("X-Amz-Date")
  valid_601652 = validateParameter(valid_601652, JString, required = false,
                                 default = nil)
  if valid_601652 != nil:
    section.add "X-Amz-Date", valid_601652
  var valid_601653 = header.getOrDefault("X-Amz-Security-Token")
  valid_601653 = validateParameter(valid_601653, JString, required = false,
                                 default = nil)
  if valid_601653 != nil:
    section.add "X-Amz-Security-Token", valid_601653
  var valid_601654 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601654 = validateParameter(valid_601654, JString, required = false,
                                 default = nil)
  if valid_601654 != nil:
    section.add "X-Amz-Content-Sha256", valid_601654
  var valid_601655 = header.getOrDefault("X-Amz-Algorithm")
  valid_601655 = validateParameter(valid_601655, JString, required = false,
                                 default = nil)
  if valid_601655 != nil:
    section.add "X-Amz-Algorithm", valid_601655
  var valid_601656 = header.getOrDefault("X-Amz-Signature")
  valid_601656 = validateParameter(valid_601656, JString, required = false,
                                 default = nil)
  if valid_601656 != nil:
    section.add "X-Amz-Signature", valid_601656
  var valid_601657 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601657 = validateParameter(valid_601657, JString, required = false,
                                 default = nil)
  if valid_601657 != nil:
    section.add "X-Amz-SignedHeaders", valid_601657
  var valid_601658 = header.getOrDefault("X-Amz-Credential")
  valid_601658 = validateParameter(valid_601658, JString, required = false,
                                 default = nil)
  if valid_601658 != nil:
    section.add "X-Amz-Credential", valid_601658
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601659: Call_GetUpdateServiceAccessPolicies_601645; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the policies that control access to the domain's document and search services. The maximum size of an access policy document is 100 KB.
  ## 
  let valid = call_601659.validator(path, query, header, formData, body)
  let scheme = call_601659.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601659.url(scheme.get, call_601659.host, call_601659.base,
                         call_601659.route, valid.getOrDefault("path"))
  result = hook(call_601659, url, valid)

proc call*(call_601660: Call_GetUpdateServiceAccessPolicies_601645;
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
  var query_601661 = newJObject()
  add(query_601661, "Action", newJString(Action))
  add(query_601661, "AccessPolicies", newJString(AccessPolicies))
  add(query_601661, "DomainName", newJString(DomainName))
  add(query_601661, "Version", newJString(Version))
  result = call_601660.call(nil, query_601661, nil, nil, nil)

var getUpdateServiceAccessPolicies* = Call_GetUpdateServiceAccessPolicies_601645(
    name: "getUpdateServiceAccessPolicies", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateServiceAccessPolicies",
    validator: validate_GetUpdateServiceAccessPolicies_601646, base: "/",
    url: url_GetUpdateServiceAccessPolicies_601647,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateStemmingOptions_601697 = ref object of OpenApiRestCall_600426
proc url_PostUpdateStemmingOptions_601699(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostUpdateStemmingOptions_601698(path: JsonNode; query: JsonNode;
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
  var valid_601700 = query.getOrDefault("Action")
  valid_601700 = validateParameter(valid_601700, JString, required = true,
                                 default = newJString("UpdateStemmingOptions"))
  if valid_601700 != nil:
    section.add "Action", valid_601700
  var valid_601701 = query.getOrDefault("Version")
  valid_601701 = validateParameter(valid_601701, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_601701 != nil:
    section.add "Version", valid_601701
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
  var valid_601702 = header.getOrDefault("X-Amz-Date")
  valid_601702 = validateParameter(valid_601702, JString, required = false,
                                 default = nil)
  if valid_601702 != nil:
    section.add "X-Amz-Date", valid_601702
  var valid_601703 = header.getOrDefault("X-Amz-Security-Token")
  valid_601703 = validateParameter(valid_601703, JString, required = false,
                                 default = nil)
  if valid_601703 != nil:
    section.add "X-Amz-Security-Token", valid_601703
  var valid_601704 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601704 = validateParameter(valid_601704, JString, required = false,
                                 default = nil)
  if valid_601704 != nil:
    section.add "X-Amz-Content-Sha256", valid_601704
  var valid_601705 = header.getOrDefault("X-Amz-Algorithm")
  valid_601705 = validateParameter(valid_601705, JString, required = false,
                                 default = nil)
  if valid_601705 != nil:
    section.add "X-Amz-Algorithm", valid_601705
  var valid_601706 = header.getOrDefault("X-Amz-Signature")
  valid_601706 = validateParameter(valid_601706, JString, required = false,
                                 default = nil)
  if valid_601706 != nil:
    section.add "X-Amz-Signature", valid_601706
  var valid_601707 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601707 = validateParameter(valid_601707, JString, required = false,
                                 default = nil)
  if valid_601707 != nil:
    section.add "X-Amz-SignedHeaders", valid_601707
  var valid_601708 = header.getOrDefault("X-Amz-Credential")
  valid_601708 = validateParameter(valid_601708, JString, required = false,
                                 default = nil)
  if valid_601708 != nil:
    section.add "X-Amz-Credential", valid_601708
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Stems: JString (required)
  ##        : Maps terms to their stems, serialized as a JSON document. The document has a single object with one property "stems" whose value is an object mapping terms to their stems. The maximum size of a stemming document is 500 KB. Example: <code>{ "stems": {"people": "person", "walking": "walk"} }</code>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_601709 = formData.getOrDefault("DomainName")
  valid_601709 = validateParameter(valid_601709, JString, required = true,
                                 default = nil)
  if valid_601709 != nil:
    section.add "DomainName", valid_601709
  var valid_601710 = formData.getOrDefault("Stems")
  valid_601710 = validateParameter(valid_601710, JString, required = true,
                                 default = nil)
  if valid_601710 != nil:
    section.add "Stems", valid_601710
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601711: Call_PostUpdateStemmingOptions_601697; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a stemming dictionary for the search domain. The stemming dictionary is used during indexing and when processing search requests. The maximum size of the stemming dictionary is 500 KB.
  ## 
  let valid = call_601711.validator(path, query, header, formData, body)
  let scheme = call_601711.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601711.url(scheme.get, call_601711.host, call_601711.base,
                         call_601711.route, valid.getOrDefault("path"))
  result = hook(call_601711, url, valid)

proc call*(call_601712: Call_PostUpdateStemmingOptions_601697; DomainName: string;
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
  var query_601713 = newJObject()
  var formData_601714 = newJObject()
  add(formData_601714, "DomainName", newJString(DomainName))
  add(query_601713, "Action", newJString(Action))
  add(formData_601714, "Stems", newJString(Stems))
  add(query_601713, "Version", newJString(Version))
  result = call_601712.call(nil, query_601713, nil, formData_601714, nil)

var postUpdateStemmingOptions* = Call_PostUpdateStemmingOptions_601697(
    name: "postUpdateStemmingOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateStemmingOptions",
    validator: validate_PostUpdateStemmingOptions_601698, base: "/",
    url: url_PostUpdateStemmingOptions_601699,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateStemmingOptions_601680 = ref object of OpenApiRestCall_600426
proc url_GetUpdateStemmingOptions_601682(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetUpdateStemmingOptions_601681(path: JsonNode; query: JsonNode;
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
  var valid_601683 = query.getOrDefault("Action")
  valid_601683 = validateParameter(valid_601683, JString, required = true,
                                 default = newJString("UpdateStemmingOptions"))
  if valid_601683 != nil:
    section.add "Action", valid_601683
  var valid_601684 = query.getOrDefault("Stems")
  valid_601684 = validateParameter(valid_601684, JString, required = true,
                                 default = nil)
  if valid_601684 != nil:
    section.add "Stems", valid_601684
  var valid_601685 = query.getOrDefault("DomainName")
  valid_601685 = validateParameter(valid_601685, JString, required = true,
                                 default = nil)
  if valid_601685 != nil:
    section.add "DomainName", valid_601685
  var valid_601686 = query.getOrDefault("Version")
  valid_601686 = validateParameter(valid_601686, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_601686 != nil:
    section.add "Version", valid_601686
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
  var valid_601687 = header.getOrDefault("X-Amz-Date")
  valid_601687 = validateParameter(valid_601687, JString, required = false,
                                 default = nil)
  if valid_601687 != nil:
    section.add "X-Amz-Date", valid_601687
  var valid_601688 = header.getOrDefault("X-Amz-Security-Token")
  valid_601688 = validateParameter(valid_601688, JString, required = false,
                                 default = nil)
  if valid_601688 != nil:
    section.add "X-Amz-Security-Token", valid_601688
  var valid_601689 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601689 = validateParameter(valid_601689, JString, required = false,
                                 default = nil)
  if valid_601689 != nil:
    section.add "X-Amz-Content-Sha256", valid_601689
  var valid_601690 = header.getOrDefault("X-Amz-Algorithm")
  valid_601690 = validateParameter(valid_601690, JString, required = false,
                                 default = nil)
  if valid_601690 != nil:
    section.add "X-Amz-Algorithm", valid_601690
  var valid_601691 = header.getOrDefault("X-Amz-Signature")
  valid_601691 = validateParameter(valid_601691, JString, required = false,
                                 default = nil)
  if valid_601691 != nil:
    section.add "X-Amz-Signature", valid_601691
  var valid_601692 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601692 = validateParameter(valid_601692, JString, required = false,
                                 default = nil)
  if valid_601692 != nil:
    section.add "X-Amz-SignedHeaders", valid_601692
  var valid_601693 = header.getOrDefault("X-Amz-Credential")
  valid_601693 = validateParameter(valid_601693, JString, required = false,
                                 default = nil)
  if valid_601693 != nil:
    section.add "X-Amz-Credential", valid_601693
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601694: Call_GetUpdateStemmingOptions_601680; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a stemming dictionary for the search domain. The stemming dictionary is used during indexing and when processing search requests. The maximum size of the stemming dictionary is 500 KB.
  ## 
  let valid = call_601694.validator(path, query, header, formData, body)
  let scheme = call_601694.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601694.url(scheme.get, call_601694.host, call_601694.base,
                         call_601694.route, valid.getOrDefault("path"))
  result = hook(call_601694, url, valid)

proc call*(call_601695: Call_GetUpdateStemmingOptions_601680; Stems: string;
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
  var query_601696 = newJObject()
  add(query_601696, "Action", newJString(Action))
  add(query_601696, "Stems", newJString(Stems))
  add(query_601696, "DomainName", newJString(DomainName))
  add(query_601696, "Version", newJString(Version))
  result = call_601695.call(nil, query_601696, nil, nil, nil)

var getUpdateStemmingOptions* = Call_GetUpdateStemmingOptions_601680(
    name: "getUpdateStemmingOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateStemmingOptions",
    validator: validate_GetUpdateStemmingOptions_601681, base: "/",
    url: url_GetUpdateStemmingOptions_601682, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateStopwordOptions_601732 = ref object of OpenApiRestCall_600426
proc url_PostUpdateStopwordOptions_601734(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostUpdateStopwordOptions_601733(path: JsonNode; query: JsonNode;
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
  var valid_601735 = query.getOrDefault("Action")
  valid_601735 = validateParameter(valid_601735, JString, required = true,
                                 default = newJString("UpdateStopwordOptions"))
  if valid_601735 != nil:
    section.add "Action", valid_601735
  var valid_601736 = query.getOrDefault("Version")
  valid_601736 = validateParameter(valid_601736, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_601736 != nil:
    section.add "Version", valid_601736
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
  var valid_601737 = header.getOrDefault("X-Amz-Date")
  valid_601737 = validateParameter(valid_601737, JString, required = false,
                                 default = nil)
  if valid_601737 != nil:
    section.add "X-Amz-Date", valid_601737
  var valid_601738 = header.getOrDefault("X-Amz-Security-Token")
  valid_601738 = validateParameter(valid_601738, JString, required = false,
                                 default = nil)
  if valid_601738 != nil:
    section.add "X-Amz-Security-Token", valid_601738
  var valid_601739 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601739 = validateParameter(valid_601739, JString, required = false,
                                 default = nil)
  if valid_601739 != nil:
    section.add "X-Amz-Content-Sha256", valid_601739
  var valid_601740 = header.getOrDefault("X-Amz-Algorithm")
  valid_601740 = validateParameter(valid_601740, JString, required = false,
                                 default = nil)
  if valid_601740 != nil:
    section.add "X-Amz-Algorithm", valid_601740
  var valid_601741 = header.getOrDefault("X-Amz-Signature")
  valid_601741 = validateParameter(valid_601741, JString, required = false,
                                 default = nil)
  if valid_601741 != nil:
    section.add "X-Amz-Signature", valid_601741
  var valid_601742 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601742 = validateParameter(valid_601742, JString, required = false,
                                 default = nil)
  if valid_601742 != nil:
    section.add "X-Amz-SignedHeaders", valid_601742
  var valid_601743 = header.getOrDefault("X-Amz-Credential")
  valid_601743 = validateParameter(valid_601743, JString, required = false,
                                 default = nil)
  if valid_601743 != nil:
    section.add "X-Amz-Credential", valid_601743
  result.add "header", section
  ## parameters in `formData` object:
  ##   Stopwords: JString (required)
  ##            : Lists stopwords serialized as a JSON document. The document has a single object with one property "stopwords" whose value is an array of strings. The maximum size of a stopwords document is 10 KB. Example: <code>{ "stopwords": ["a", "an", "the", "of"] }</code>
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Stopwords` field"
  var valid_601744 = formData.getOrDefault("Stopwords")
  valid_601744 = validateParameter(valid_601744, JString, required = true,
                                 default = nil)
  if valid_601744 != nil:
    section.add "Stopwords", valid_601744
  var valid_601745 = formData.getOrDefault("DomainName")
  valid_601745 = validateParameter(valid_601745, JString, required = true,
                                 default = nil)
  if valid_601745 != nil:
    section.add "DomainName", valid_601745
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601746: Call_PostUpdateStopwordOptions_601732; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures stopwords for the search domain. Stopwords are used during indexing and when processing search requests. The maximum size of the stopwords dictionary is 10 KB.
  ## 
  let valid = call_601746.validator(path, query, header, formData, body)
  let scheme = call_601746.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601746.url(scheme.get, call_601746.host, call_601746.base,
                         call_601746.route, valid.getOrDefault("path"))
  result = hook(call_601746, url, valid)

proc call*(call_601747: Call_PostUpdateStopwordOptions_601732; Stopwords: string;
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
  var query_601748 = newJObject()
  var formData_601749 = newJObject()
  add(formData_601749, "Stopwords", newJString(Stopwords))
  add(formData_601749, "DomainName", newJString(DomainName))
  add(query_601748, "Action", newJString(Action))
  add(query_601748, "Version", newJString(Version))
  result = call_601747.call(nil, query_601748, nil, formData_601749, nil)

var postUpdateStopwordOptions* = Call_PostUpdateStopwordOptions_601732(
    name: "postUpdateStopwordOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateStopwordOptions",
    validator: validate_PostUpdateStopwordOptions_601733, base: "/",
    url: url_PostUpdateStopwordOptions_601734,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateStopwordOptions_601715 = ref object of OpenApiRestCall_600426
proc url_GetUpdateStopwordOptions_601717(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetUpdateStopwordOptions_601716(path: JsonNode; query: JsonNode;
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
  var valid_601718 = query.getOrDefault("Action")
  valid_601718 = validateParameter(valid_601718, JString, required = true,
                                 default = newJString("UpdateStopwordOptions"))
  if valid_601718 != nil:
    section.add "Action", valid_601718
  var valid_601719 = query.getOrDefault("Stopwords")
  valid_601719 = validateParameter(valid_601719, JString, required = true,
                                 default = nil)
  if valid_601719 != nil:
    section.add "Stopwords", valid_601719
  var valid_601720 = query.getOrDefault("DomainName")
  valid_601720 = validateParameter(valid_601720, JString, required = true,
                                 default = nil)
  if valid_601720 != nil:
    section.add "DomainName", valid_601720
  var valid_601721 = query.getOrDefault("Version")
  valid_601721 = validateParameter(valid_601721, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_601721 != nil:
    section.add "Version", valid_601721
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
  var valid_601722 = header.getOrDefault("X-Amz-Date")
  valid_601722 = validateParameter(valid_601722, JString, required = false,
                                 default = nil)
  if valid_601722 != nil:
    section.add "X-Amz-Date", valid_601722
  var valid_601723 = header.getOrDefault("X-Amz-Security-Token")
  valid_601723 = validateParameter(valid_601723, JString, required = false,
                                 default = nil)
  if valid_601723 != nil:
    section.add "X-Amz-Security-Token", valid_601723
  var valid_601724 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601724 = validateParameter(valid_601724, JString, required = false,
                                 default = nil)
  if valid_601724 != nil:
    section.add "X-Amz-Content-Sha256", valid_601724
  var valid_601725 = header.getOrDefault("X-Amz-Algorithm")
  valid_601725 = validateParameter(valid_601725, JString, required = false,
                                 default = nil)
  if valid_601725 != nil:
    section.add "X-Amz-Algorithm", valid_601725
  var valid_601726 = header.getOrDefault("X-Amz-Signature")
  valid_601726 = validateParameter(valid_601726, JString, required = false,
                                 default = nil)
  if valid_601726 != nil:
    section.add "X-Amz-Signature", valid_601726
  var valid_601727 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601727 = validateParameter(valid_601727, JString, required = false,
                                 default = nil)
  if valid_601727 != nil:
    section.add "X-Amz-SignedHeaders", valid_601727
  var valid_601728 = header.getOrDefault("X-Amz-Credential")
  valid_601728 = validateParameter(valid_601728, JString, required = false,
                                 default = nil)
  if valid_601728 != nil:
    section.add "X-Amz-Credential", valid_601728
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601729: Call_GetUpdateStopwordOptions_601715; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures stopwords for the search domain. Stopwords are used during indexing and when processing search requests. The maximum size of the stopwords dictionary is 10 KB.
  ## 
  let valid = call_601729.validator(path, query, header, formData, body)
  let scheme = call_601729.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601729.url(scheme.get, call_601729.host, call_601729.base,
                         call_601729.route, valid.getOrDefault("path"))
  result = hook(call_601729, url, valid)

proc call*(call_601730: Call_GetUpdateStopwordOptions_601715; Stopwords: string;
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
  var query_601731 = newJObject()
  add(query_601731, "Action", newJString(Action))
  add(query_601731, "Stopwords", newJString(Stopwords))
  add(query_601731, "DomainName", newJString(DomainName))
  add(query_601731, "Version", newJString(Version))
  result = call_601730.call(nil, query_601731, nil, nil, nil)

var getUpdateStopwordOptions* = Call_GetUpdateStopwordOptions_601715(
    name: "getUpdateStopwordOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateStopwordOptions",
    validator: validate_GetUpdateStopwordOptions_601716, base: "/",
    url: url_GetUpdateStopwordOptions_601717, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateSynonymOptions_601767 = ref object of OpenApiRestCall_600426
proc url_PostUpdateSynonymOptions_601769(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_PostUpdateSynonymOptions_601768(path: JsonNode; query: JsonNode;
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
  var valid_601770 = query.getOrDefault("Action")
  valid_601770 = validateParameter(valid_601770, JString, required = true,
                                 default = newJString("UpdateSynonymOptions"))
  if valid_601770 != nil:
    section.add "Action", valid_601770
  var valid_601771 = query.getOrDefault("Version")
  valid_601771 = validateParameter(valid_601771, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_601771 != nil:
    section.add "Version", valid_601771
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
  var valid_601772 = header.getOrDefault("X-Amz-Date")
  valid_601772 = validateParameter(valid_601772, JString, required = false,
                                 default = nil)
  if valid_601772 != nil:
    section.add "X-Amz-Date", valid_601772
  var valid_601773 = header.getOrDefault("X-Amz-Security-Token")
  valid_601773 = validateParameter(valid_601773, JString, required = false,
                                 default = nil)
  if valid_601773 != nil:
    section.add "X-Amz-Security-Token", valid_601773
  var valid_601774 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601774 = validateParameter(valid_601774, JString, required = false,
                                 default = nil)
  if valid_601774 != nil:
    section.add "X-Amz-Content-Sha256", valid_601774
  var valid_601775 = header.getOrDefault("X-Amz-Algorithm")
  valid_601775 = validateParameter(valid_601775, JString, required = false,
                                 default = nil)
  if valid_601775 != nil:
    section.add "X-Amz-Algorithm", valid_601775
  var valid_601776 = header.getOrDefault("X-Amz-Signature")
  valid_601776 = validateParameter(valid_601776, JString, required = false,
                                 default = nil)
  if valid_601776 != nil:
    section.add "X-Amz-Signature", valid_601776
  var valid_601777 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601777 = validateParameter(valid_601777, JString, required = false,
                                 default = nil)
  if valid_601777 != nil:
    section.add "X-Amz-SignedHeaders", valid_601777
  var valid_601778 = header.getOrDefault("X-Amz-Credential")
  valid_601778 = validateParameter(valid_601778, JString, required = false,
                                 default = nil)
  if valid_601778 != nil:
    section.add "X-Amz-Credential", valid_601778
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Synonyms: JString (required)
  ##           : Maps terms to their synonyms, serialized as a JSON document. The document has a single object with one property "synonyms" whose value is an object mapping terms to their synonyms. Each synonym is a simple string or an array of strings. The maximum size of a stopwords document is 100 KB. Example: <code>{ "synonyms": {"cat": ["feline", "kitten"], "puppy": "dog"} }</code>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_601779 = formData.getOrDefault("DomainName")
  valid_601779 = validateParameter(valid_601779, JString, required = true,
                                 default = nil)
  if valid_601779 != nil:
    section.add "DomainName", valid_601779
  var valid_601780 = formData.getOrDefault("Synonyms")
  valid_601780 = validateParameter(valid_601780, JString, required = true,
                                 default = nil)
  if valid_601780 != nil:
    section.add "Synonyms", valid_601780
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601781: Call_PostUpdateSynonymOptions_601767; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a synonym dictionary for the search domain. The synonym dictionary is used during indexing to configure mappings for terms that occur in text fields. The maximum size of the synonym dictionary is 100 KB. 
  ## 
  let valid = call_601781.validator(path, query, header, formData, body)
  let scheme = call_601781.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601781.url(scheme.get, call_601781.host, call_601781.base,
                         call_601781.route, valid.getOrDefault("path"))
  result = hook(call_601781, url, valid)

proc call*(call_601782: Call_PostUpdateSynonymOptions_601767; DomainName: string;
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
  var query_601783 = newJObject()
  var formData_601784 = newJObject()
  add(formData_601784, "DomainName", newJString(DomainName))
  add(formData_601784, "Synonyms", newJString(Synonyms))
  add(query_601783, "Action", newJString(Action))
  add(query_601783, "Version", newJString(Version))
  result = call_601782.call(nil, query_601783, nil, formData_601784, nil)

var postUpdateSynonymOptions* = Call_PostUpdateSynonymOptions_601767(
    name: "postUpdateSynonymOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateSynonymOptions",
    validator: validate_PostUpdateSynonymOptions_601768, base: "/",
    url: url_PostUpdateSynonymOptions_601769, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateSynonymOptions_601750 = ref object of OpenApiRestCall_600426
proc url_GetUpdateSynonymOptions_601752(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode): string =
  result = $protocol & "://" & host & base & route

proc validate_GetUpdateSynonymOptions_601751(path: JsonNode; query: JsonNode;
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
  var valid_601753 = query.getOrDefault("Action")
  valid_601753 = validateParameter(valid_601753, JString, required = true,
                                 default = newJString("UpdateSynonymOptions"))
  if valid_601753 != nil:
    section.add "Action", valid_601753
  var valid_601754 = query.getOrDefault("Synonyms")
  valid_601754 = validateParameter(valid_601754, JString, required = true,
                                 default = nil)
  if valid_601754 != nil:
    section.add "Synonyms", valid_601754
  var valid_601755 = query.getOrDefault("DomainName")
  valid_601755 = validateParameter(valid_601755, JString, required = true,
                                 default = nil)
  if valid_601755 != nil:
    section.add "DomainName", valid_601755
  var valid_601756 = query.getOrDefault("Version")
  valid_601756 = validateParameter(valid_601756, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_601756 != nil:
    section.add "Version", valid_601756
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
  var valid_601757 = header.getOrDefault("X-Amz-Date")
  valid_601757 = validateParameter(valid_601757, JString, required = false,
                                 default = nil)
  if valid_601757 != nil:
    section.add "X-Amz-Date", valid_601757
  var valid_601758 = header.getOrDefault("X-Amz-Security-Token")
  valid_601758 = validateParameter(valid_601758, JString, required = false,
                                 default = nil)
  if valid_601758 != nil:
    section.add "X-Amz-Security-Token", valid_601758
  var valid_601759 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601759 = validateParameter(valid_601759, JString, required = false,
                                 default = nil)
  if valid_601759 != nil:
    section.add "X-Amz-Content-Sha256", valid_601759
  var valid_601760 = header.getOrDefault("X-Amz-Algorithm")
  valid_601760 = validateParameter(valid_601760, JString, required = false,
                                 default = nil)
  if valid_601760 != nil:
    section.add "X-Amz-Algorithm", valid_601760
  var valid_601761 = header.getOrDefault("X-Amz-Signature")
  valid_601761 = validateParameter(valid_601761, JString, required = false,
                                 default = nil)
  if valid_601761 != nil:
    section.add "X-Amz-Signature", valid_601761
  var valid_601762 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601762 = validateParameter(valid_601762, JString, required = false,
                                 default = nil)
  if valid_601762 != nil:
    section.add "X-Amz-SignedHeaders", valid_601762
  var valid_601763 = header.getOrDefault("X-Amz-Credential")
  valid_601763 = validateParameter(valid_601763, JString, required = false,
                                 default = nil)
  if valid_601763 != nil:
    section.add "X-Amz-Credential", valid_601763
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601764: Call_GetUpdateSynonymOptions_601750; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a synonym dictionary for the search domain. The synonym dictionary is used during indexing to configure mappings for terms that occur in text fields. The maximum size of the synonym dictionary is 100 KB. 
  ## 
  let valid = call_601764.validator(path, query, header, formData, body)
  let scheme = call_601764.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601764.url(scheme.get, call_601764.host, call_601764.base,
                         call_601764.route, valid.getOrDefault("path"))
  result = hook(call_601764, url, valid)

proc call*(call_601765: Call_GetUpdateSynonymOptions_601750; Synonyms: string;
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
  var query_601766 = newJObject()
  add(query_601766, "Action", newJString(Action))
  add(query_601766, "Synonyms", newJString(Synonyms))
  add(query_601766, "DomainName", newJString(DomainName))
  add(query_601766, "Version", newJString(Version))
  result = call_601765.call(nil, query_601766, nil, nil, nil)

var getUpdateSynonymOptions* = Call_GetUpdateSynonymOptions_601750(
    name: "getUpdateSynonymOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateSynonymOptions",
    validator: validate_GetUpdateSynonymOptions_601751, base: "/",
    url: url_GetUpdateSynonymOptions_601752, schemes: {Scheme.Https, Scheme.Http})
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
  echo recall.headers
  recall.headers.del "Host"
  recall.url = $url

method hook(call: OpenApiRestCall; url: string; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, "")
  result.sign(input.getOrDefault("query"), SHA256)
