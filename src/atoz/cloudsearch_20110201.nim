
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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
              path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_605589 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_605589](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_605589): Option[Scheme] {.used.} =
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
proc queryString(query: JsonNode): string {.used.} =
  var qs: seq[KeyVal]
  if query == nil:
    return ""
  for k, v in query.pairs:
    qs.add (key: k, val: v.getStr)
  result = encodeQuery(qs)

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.used.} =
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
    case js.kind
    of JInt, JFloat, JNull, JBool:
      head = $js
    of JString:
      head = js.getStr
    else:
      return
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_PostCreateDomain_606198 = ref object of OpenApiRestCall_605589
proc url_PostCreateDomain_606200(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDomain_606199(path: JsonNode; query: JsonNode;
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
  var valid_606201 = query.getOrDefault("Action")
  valid_606201 = validateParameter(valid_606201, JString, required = true,
                                 default = newJString("CreateDomain"))
  if valid_606201 != nil:
    section.add "Action", valid_606201
  var valid_606202 = query.getOrDefault("Version")
  valid_606202 = validateParameter(valid_606202, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_606202 != nil:
    section.add "Version", valid_606202
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606203 = header.getOrDefault("X-Amz-Signature")
  valid_606203 = validateParameter(valid_606203, JString, required = false,
                                 default = nil)
  if valid_606203 != nil:
    section.add "X-Amz-Signature", valid_606203
  var valid_606204 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606204 = validateParameter(valid_606204, JString, required = false,
                                 default = nil)
  if valid_606204 != nil:
    section.add "X-Amz-Content-Sha256", valid_606204
  var valid_606205 = header.getOrDefault("X-Amz-Date")
  valid_606205 = validateParameter(valid_606205, JString, required = false,
                                 default = nil)
  if valid_606205 != nil:
    section.add "X-Amz-Date", valid_606205
  var valid_606206 = header.getOrDefault("X-Amz-Credential")
  valid_606206 = validateParameter(valid_606206, JString, required = false,
                                 default = nil)
  if valid_606206 != nil:
    section.add "X-Amz-Credential", valid_606206
  var valid_606207 = header.getOrDefault("X-Amz-Security-Token")
  valid_606207 = validateParameter(valid_606207, JString, required = false,
                                 default = nil)
  if valid_606207 != nil:
    section.add "X-Amz-Security-Token", valid_606207
  var valid_606208 = header.getOrDefault("X-Amz-Algorithm")
  valid_606208 = validateParameter(valid_606208, JString, required = false,
                                 default = nil)
  if valid_606208 != nil:
    section.add "X-Amz-Algorithm", valid_606208
  var valid_606209 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606209 = validateParameter(valid_606209, JString, required = false,
                                 default = nil)
  if valid_606209 != nil:
    section.add "X-Amz-SignedHeaders", valid_606209
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_606210 = formData.getOrDefault("DomainName")
  valid_606210 = validateParameter(valid_606210, JString, required = true,
                                 default = nil)
  if valid_606210 != nil:
    section.add "DomainName", valid_606210
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606211: Call_PostCreateDomain_606198; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new search domain.
  ## 
  let valid = call_606211.validator(path, query, header, formData, body)
  let scheme = call_606211.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606211.url(scheme.get, call_606211.host, call_606211.base,
                         call_606211.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606211, url, valid)

proc call*(call_606212: Call_PostCreateDomain_606198; DomainName: string;
          Action: string = "CreateDomain"; Version: string = "2011-02-01"): Recallable =
  ## postCreateDomain
  ## Creates a new search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606213 = newJObject()
  var formData_606214 = newJObject()
  add(formData_606214, "DomainName", newJString(DomainName))
  add(query_606213, "Action", newJString(Action))
  add(query_606213, "Version", newJString(Version))
  result = call_606212.call(nil, query_606213, nil, formData_606214, nil)

var postCreateDomain* = Call_PostCreateDomain_606198(name: "postCreateDomain",
    meth: HttpMethod.HttpPost, host: "cloudsearch.amazonaws.com",
    route: "/#Action=CreateDomain", validator: validate_PostCreateDomain_606199,
    base: "/", url: url_PostCreateDomain_606200,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDomain_605927 = ref object of OpenApiRestCall_605589
proc url_GetCreateDomain_605929(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDomain_605928(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Creates a new search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_606041 = query.getOrDefault("DomainName")
  valid_606041 = validateParameter(valid_606041, JString, required = true,
                                 default = nil)
  if valid_606041 != nil:
    section.add "DomainName", valid_606041
  var valid_606055 = query.getOrDefault("Action")
  valid_606055 = validateParameter(valid_606055, JString, required = true,
                                 default = newJString("CreateDomain"))
  if valid_606055 != nil:
    section.add "Action", valid_606055
  var valid_606056 = query.getOrDefault("Version")
  valid_606056 = validateParameter(valid_606056, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_606056 != nil:
    section.add "Version", valid_606056
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606057 = header.getOrDefault("X-Amz-Signature")
  valid_606057 = validateParameter(valid_606057, JString, required = false,
                                 default = nil)
  if valid_606057 != nil:
    section.add "X-Amz-Signature", valid_606057
  var valid_606058 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606058 = validateParameter(valid_606058, JString, required = false,
                                 default = nil)
  if valid_606058 != nil:
    section.add "X-Amz-Content-Sha256", valid_606058
  var valid_606059 = header.getOrDefault("X-Amz-Date")
  valid_606059 = validateParameter(valid_606059, JString, required = false,
                                 default = nil)
  if valid_606059 != nil:
    section.add "X-Amz-Date", valid_606059
  var valid_606060 = header.getOrDefault("X-Amz-Credential")
  valid_606060 = validateParameter(valid_606060, JString, required = false,
                                 default = nil)
  if valid_606060 != nil:
    section.add "X-Amz-Credential", valid_606060
  var valid_606061 = header.getOrDefault("X-Amz-Security-Token")
  valid_606061 = validateParameter(valid_606061, JString, required = false,
                                 default = nil)
  if valid_606061 != nil:
    section.add "X-Amz-Security-Token", valid_606061
  var valid_606062 = header.getOrDefault("X-Amz-Algorithm")
  valid_606062 = validateParameter(valid_606062, JString, required = false,
                                 default = nil)
  if valid_606062 != nil:
    section.add "X-Amz-Algorithm", valid_606062
  var valid_606063 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606063 = validateParameter(valid_606063, JString, required = false,
                                 default = nil)
  if valid_606063 != nil:
    section.add "X-Amz-SignedHeaders", valid_606063
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606086: Call_GetCreateDomain_605927; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new search domain.
  ## 
  let valid = call_606086.validator(path, query, header, formData, body)
  let scheme = call_606086.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606086.url(scheme.get, call_606086.host, call_606086.base,
                         call_606086.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606086, url, valid)

proc call*(call_606157: Call_GetCreateDomain_605927; DomainName: string;
          Action: string = "CreateDomain"; Version: string = "2011-02-01"): Recallable =
  ## getCreateDomain
  ## Creates a new search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606158 = newJObject()
  add(query_606158, "DomainName", newJString(DomainName))
  add(query_606158, "Action", newJString(Action))
  add(query_606158, "Version", newJString(Version))
  result = call_606157.call(nil, query_606158, nil, nil, nil)

var getCreateDomain* = Call_GetCreateDomain_605927(name: "getCreateDomain",
    meth: HttpMethod.HttpGet, host: "cloudsearch.amazonaws.com",
    route: "/#Action=CreateDomain", validator: validate_GetCreateDomain_605928,
    base: "/", url: url_GetCreateDomain_605929, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDefineIndexField_606237 = ref object of OpenApiRestCall_605589
proc url_PostDefineIndexField_606239(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDefineIndexField_606238(path: JsonNode; query: JsonNode;
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
  var valid_606240 = query.getOrDefault("Action")
  valid_606240 = validateParameter(valid_606240, JString, required = true,
                                 default = newJString("DefineIndexField"))
  if valid_606240 != nil:
    section.add "Action", valid_606240
  var valid_606241 = query.getOrDefault("Version")
  valid_606241 = validateParameter(valid_606241, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_606241 != nil:
    section.add "Version", valid_606241
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606242 = header.getOrDefault("X-Amz-Signature")
  valid_606242 = validateParameter(valid_606242, JString, required = false,
                                 default = nil)
  if valid_606242 != nil:
    section.add "X-Amz-Signature", valid_606242
  var valid_606243 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606243 = validateParameter(valid_606243, JString, required = false,
                                 default = nil)
  if valid_606243 != nil:
    section.add "X-Amz-Content-Sha256", valid_606243
  var valid_606244 = header.getOrDefault("X-Amz-Date")
  valid_606244 = validateParameter(valid_606244, JString, required = false,
                                 default = nil)
  if valid_606244 != nil:
    section.add "X-Amz-Date", valid_606244
  var valid_606245 = header.getOrDefault("X-Amz-Credential")
  valid_606245 = validateParameter(valid_606245, JString, required = false,
                                 default = nil)
  if valid_606245 != nil:
    section.add "X-Amz-Credential", valid_606245
  var valid_606246 = header.getOrDefault("X-Amz-Security-Token")
  valid_606246 = validateParameter(valid_606246, JString, required = false,
                                 default = nil)
  if valid_606246 != nil:
    section.add "X-Amz-Security-Token", valid_606246
  var valid_606247 = header.getOrDefault("X-Amz-Algorithm")
  valid_606247 = validateParameter(valid_606247, JString, required = false,
                                 default = nil)
  if valid_606247 != nil:
    section.add "X-Amz-Algorithm", valid_606247
  var valid_606248 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606248 = validateParameter(valid_606248, JString, required = false,
                                 default = nil)
  if valid_606248 != nil:
    section.add "X-Amz-SignedHeaders", valid_606248
  result.add "header", section
  ## parameters in `formData` object:
  ##   IndexField.UIntOptions: JString
  ##                         : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for an unsigned integer field. Present if <code>IndexFieldType</code> specifies the field is of type unsigned integer.
  ##   IndexField.SourceAttributes: JArray
  ##                              : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## An optional list of source attributes that provide data for this index field. If not specified, the data is pulled from a source attribute with the same name as this <code>IndexField</code>. When one or more source attributes are specified, an optional data transformation can be applied to the source data when populating the index field. You can configure a maximum of 20 sources for an <code>IndexField</code>.
  ##   IndexField.IndexFieldType: JString
  ##                            : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## The type of field. Based on this type, exactly one of the <a>UIntOptions</a>, <a>LiteralOptions</a> or <a>TextOptions</a> must be present.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   IndexField.TextOptions: JString
  ##                         : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for text field. Present if <code>IndexFieldType</code> specifies the field is of type text.
  ##   IndexField.LiteralOptions: JString
  ##                            : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for literal field. Present if <code>IndexFieldType</code> specifies the field is of type literal.
  ##   IndexField.IndexFieldName: JString
  ##                            : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## The name of a field in the search index. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  section = newJObject()
  var valid_606249 = formData.getOrDefault("IndexField.UIntOptions")
  valid_606249 = validateParameter(valid_606249, JString, required = false,
                                 default = nil)
  if valid_606249 != nil:
    section.add "IndexField.UIntOptions", valid_606249
  var valid_606250 = formData.getOrDefault("IndexField.SourceAttributes")
  valid_606250 = validateParameter(valid_606250, JArray, required = false,
                                 default = nil)
  if valid_606250 != nil:
    section.add "IndexField.SourceAttributes", valid_606250
  var valid_606251 = formData.getOrDefault("IndexField.IndexFieldType")
  valid_606251 = validateParameter(valid_606251, JString, required = false,
                                 default = nil)
  if valid_606251 != nil:
    section.add "IndexField.IndexFieldType", valid_606251
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_606252 = formData.getOrDefault("DomainName")
  valid_606252 = validateParameter(valid_606252, JString, required = true,
                                 default = nil)
  if valid_606252 != nil:
    section.add "DomainName", valid_606252
  var valid_606253 = formData.getOrDefault("IndexField.TextOptions")
  valid_606253 = validateParameter(valid_606253, JString, required = false,
                                 default = nil)
  if valid_606253 != nil:
    section.add "IndexField.TextOptions", valid_606253
  var valid_606254 = formData.getOrDefault("IndexField.LiteralOptions")
  valid_606254 = validateParameter(valid_606254, JString, required = false,
                                 default = nil)
  if valid_606254 != nil:
    section.add "IndexField.LiteralOptions", valid_606254
  var valid_606255 = formData.getOrDefault("IndexField.IndexFieldName")
  valid_606255 = validateParameter(valid_606255, JString, required = false,
                                 default = nil)
  if valid_606255 != nil:
    section.add "IndexField.IndexFieldName", valid_606255
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606256: Call_PostDefineIndexField_606237; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures an <code>IndexField</code> for the search domain. Used to create new fields and modify existing ones. If the field exists, the new configuration replaces the old one. You can configure a maximum of 200 index fields.
  ## 
  let valid = call_606256.validator(path, query, header, formData, body)
  let scheme = call_606256.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606256.url(scheme.get, call_606256.host, call_606256.base,
                         call_606256.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606256, url, valid)

proc call*(call_606257: Call_PostDefineIndexField_606237; DomainName: string;
          IndexFieldUIntOptions: string = "";
          IndexFieldSourceAttributes: JsonNode = nil;
          IndexFieldIndexFieldType: string = ""; IndexFieldTextOptions: string = "";
          IndexFieldLiteralOptions: string = "";
          Action: string = "DefineIndexField";
          IndexFieldIndexFieldName: string = ""; Version: string = "2011-02-01"): Recallable =
  ## postDefineIndexField
  ## Configures an <code>IndexField</code> for the search domain. Used to create new fields and modify existing ones. If the field exists, the new configuration replaces the old one. You can configure a maximum of 200 index fields.
  ##   IndexFieldUIntOptions: string
  ##                        : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for an unsigned integer field. Present if <code>IndexFieldType</code> specifies the field is of type unsigned integer.
  ##   IndexFieldSourceAttributes: JArray
  ##                             : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## An optional list of source attributes that provide data for this index field. If not specified, the data is pulled from a source attribute with the same name as this <code>IndexField</code>. When one or more source attributes are specified, an optional data transformation can be applied to the source data when populating the index field. You can configure a maximum of 20 sources for an <code>IndexField</code>.
  ##   IndexFieldIndexFieldType: string
  ##                           : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## The type of field. Based on this type, exactly one of the <a>UIntOptions</a>, <a>LiteralOptions</a> or <a>TextOptions</a> must be present.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   IndexFieldTextOptions: string
  ##                        : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for text field. Present if <code>IndexFieldType</code> specifies the field is of type text.
  ##   IndexFieldLiteralOptions: string
  ##                           : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for literal field. Present if <code>IndexFieldType</code> specifies the field is of type literal.
  ##   Action: string (required)
  ##   IndexFieldIndexFieldName: string
  ##                           : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## The name of a field in the search index. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   Version: string (required)
  var query_606258 = newJObject()
  var formData_606259 = newJObject()
  add(formData_606259, "IndexField.UIntOptions", newJString(IndexFieldUIntOptions))
  if IndexFieldSourceAttributes != nil:
    formData_606259.add "IndexField.SourceAttributes", IndexFieldSourceAttributes
  add(formData_606259, "IndexField.IndexFieldType",
      newJString(IndexFieldIndexFieldType))
  add(formData_606259, "DomainName", newJString(DomainName))
  add(formData_606259, "IndexField.TextOptions", newJString(IndexFieldTextOptions))
  add(formData_606259, "IndexField.LiteralOptions",
      newJString(IndexFieldLiteralOptions))
  add(query_606258, "Action", newJString(Action))
  add(formData_606259, "IndexField.IndexFieldName",
      newJString(IndexFieldIndexFieldName))
  add(query_606258, "Version", newJString(Version))
  result = call_606257.call(nil, query_606258, nil, formData_606259, nil)

var postDefineIndexField* = Call_PostDefineIndexField_606237(
    name: "postDefineIndexField", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineIndexField",
    validator: validate_PostDefineIndexField_606238, base: "/",
    url: url_PostDefineIndexField_606239, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDefineIndexField_606215 = ref object of OpenApiRestCall_605589
proc url_GetDefineIndexField_606217(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDefineIndexField_606216(path: JsonNode; query: JsonNode;
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
  ##   IndexField.IndexFieldType: JString
  ##                            : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## The type of field. Based on this type, exactly one of the <a>UIntOptions</a>, <a>LiteralOptions</a> or <a>TextOptions</a> must be present.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   IndexField.IndexFieldName: JString
  ##                            : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## The name of a field in the search index. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   IndexField.UIntOptions: JString
  ##                         : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for an unsigned integer field. Present if <code>IndexFieldType</code> specifies the field is of type unsigned integer.
  ##   IndexField.SourceAttributes: JArray
  ##                              : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## An optional list of source attributes that provide data for this index field. If not specified, the data is pulled from a source attribute with the same name as this <code>IndexField</code>. When one or more source attributes are specified, an optional data transformation can be applied to the source data when populating the index field. You can configure a maximum of 20 sources for an <code>IndexField</code>.
  ##   Action: JString (required)
  ##   IndexField.LiteralOptions: JString
  ##                            : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for literal field. Present if <code>IndexFieldType</code> specifies the field is of type literal.
  ##   Version: JString (required)
  section = newJObject()
  var valid_606218 = query.getOrDefault("IndexField.TextOptions")
  valid_606218 = validateParameter(valid_606218, JString, required = false,
                                 default = nil)
  if valid_606218 != nil:
    section.add "IndexField.TextOptions", valid_606218
  var valid_606219 = query.getOrDefault("IndexField.IndexFieldType")
  valid_606219 = validateParameter(valid_606219, JString, required = false,
                                 default = nil)
  if valid_606219 != nil:
    section.add "IndexField.IndexFieldType", valid_606219
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_606220 = query.getOrDefault("DomainName")
  valid_606220 = validateParameter(valid_606220, JString, required = true,
                                 default = nil)
  if valid_606220 != nil:
    section.add "DomainName", valid_606220
  var valid_606221 = query.getOrDefault("IndexField.IndexFieldName")
  valid_606221 = validateParameter(valid_606221, JString, required = false,
                                 default = nil)
  if valid_606221 != nil:
    section.add "IndexField.IndexFieldName", valid_606221
  var valid_606222 = query.getOrDefault("IndexField.UIntOptions")
  valid_606222 = validateParameter(valid_606222, JString, required = false,
                                 default = nil)
  if valid_606222 != nil:
    section.add "IndexField.UIntOptions", valid_606222
  var valid_606223 = query.getOrDefault("IndexField.SourceAttributes")
  valid_606223 = validateParameter(valid_606223, JArray, required = false,
                                 default = nil)
  if valid_606223 != nil:
    section.add "IndexField.SourceAttributes", valid_606223
  var valid_606224 = query.getOrDefault("Action")
  valid_606224 = validateParameter(valid_606224, JString, required = true,
                                 default = newJString("DefineIndexField"))
  if valid_606224 != nil:
    section.add "Action", valid_606224
  var valid_606225 = query.getOrDefault("IndexField.LiteralOptions")
  valid_606225 = validateParameter(valid_606225, JString, required = false,
                                 default = nil)
  if valid_606225 != nil:
    section.add "IndexField.LiteralOptions", valid_606225
  var valid_606226 = query.getOrDefault("Version")
  valid_606226 = validateParameter(valid_606226, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_606226 != nil:
    section.add "Version", valid_606226
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606227 = header.getOrDefault("X-Amz-Signature")
  valid_606227 = validateParameter(valid_606227, JString, required = false,
                                 default = nil)
  if valid_606227 != nil:
    section.add "X-Amz-Signature", valid_606227
  var valid_606228 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606228 = validateParameter(valid_606228, JString, required = false,
                                 default = nil)
  if valid_606228 != nil:
    section.add "X-Amz-Content-Sha256", valid_606228
  var valid_606229 = header.getOrDefault("X-Amz-Date")
  valid_606229 = validateParameter(valid_606229, JString, required = false,
                                 default = nil)
  if valid_606229 != nil:
    section.add "X-Amz-Date", valid_606229
  var valid_606230 = header.getOrDefault("X-Amz-Credential")
  valid_606230 = validateParameter(valid_606230, JString, required = false,
                                 default = nil)
  if valid_606230 != nil:
    section.add "X-Amz-Credential", valid_606230
  var valid_606231 = header.getOrDefault("X-Amz-Security-Token")
  valid_606231 = validateParameter(valid_606231, JString, required = false,
                                 default = nil)
  if valid_606231 != nil:
    section.add "X-Amz-Security-Token", valid_606231
  var valid_606232 = header.getOrDefault("X-Amz-Algorithm")
  valid_606232 = validateParameter(valid_606232, JString, required = false,
                                 default = nil)
  if valid_606232 != nil:
    section.add "X-Amz-Algorithm", valid_606232
  var valid_606233 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606233 = validateParameter(valid_606233, JString, required = false,
                                 default = nil)
  if valid_606233 != nil:
    section.add "X-Amz-SignedHeaders", valid_606233
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606234: Call_GetDefineIndexField_606215; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures an <code>IndexField</code> for the search domain. Used to create new fields and modify existing ones. If the field exists, the new configuration replaces the old one. You can configure a maximum of 200 index fields.
  ## 
  let valid = call_606234.validator(path, query, header, formData, body)
  let scheme = call_606234.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606234.url(scheme.get, call_606234.host, call_606234.base,
                         call_606234.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606234, url, valid)

proc call*(call_606235: Call_GetDefineIndexField_606215; DomainName: string;
          IndexFieldTextOptions: string = ""; IndexFieldIndexFieldType: string = "";
          IndexFieldIndexFieldName: string = ""; IndexFieldUIntOptions: string = "";
          IndexFieldSourceAttributes: JsonNode = nil;
          Action: string = "DefineIndexField";
          IndexFieldLiteralOptions: string = ""; Version: string = "2011-02-01"): Recallable =
  ## getDefineIndexField
  ## Configures an <code>IndexField</code> for the search domain. Used to create new fields and modify existing ones. If the field exists, the new configuration replaces the old one. You can configure a maximum of 200 index fields.
  ##   IndexFieldTextOptions: string
  ##                        : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for text field. Present if <code>IndexFieldType</code> specifies the field is of type text.
  ##   IndexFieldIndexFieldType: string
  ##                           : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## The type of field. Based on this type, exactly one of the <a>UIntOptions</a>, <a>LiteralOptions</a> or <a>TextOptions</a> must be present.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   IndexFieldIndexFieldName: string
  ##                           : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## The name of a field in the search index. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   IndexFieldUIntOptions: string
  ##                        : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for an unsigned integer field. Present if <code>IndexFieldType</code> specifies the field is of type unsigned integer.
  ##   IndexFieldSourceAttributes: JArray
  ##                             : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## An optional list of source attributes that provide data for this index field. If not specified, the data is pulled from a source attribute with the same name as this <code>IndexField</code>. When one or more source attributes are specified, an optional data transformation can be applied to the source data when populating the index field. You can configure a maximum of 20 sources for an <code>IndexField</code>.
  ##   Action: string (required)
  ##   IndexFieldLiteralOptions: string
  ##                           : Defines a field in the index, including its name, type, and the source of its data. The <code>IndexFieldType</code> indicates which of the options will be present. It is invalid to specify options for a type other than the <code>IndexFieldType</code>.
  ## Options for literal field. Present if <code>IndexFieldType</code> specifies the field is of type literal.
  ##   Version: string (required)
  var query_606236 = newJObject()
  add(query_606236, "IndexField.TextOptions", newJString(IndexFieldTextOptions))
  add(query_606236, "IndexField.IndexFieldType",
      newJString(IndexFieldIndexFieldType))
  add(query_606236, "DomainName", newJString(DomainName))
  add(query_606236, "IndexField.IndexFieldName",
      newJString(IndexFieldIndexFieldName))
  add(query_606236, "IndexField.UIntOptions", newJString(IndexFieldUIntOptions))
  if IndexFieldSourceAttributes != nil:
    query_606236.add "IndexField.SourceAttributes", IndexFieldSourceAttributes
  add(query_606236, "Action", newJString(Action))
  add(query_606236, "IndexField.LiteralOptions",
      newJString(IndexFieldLiteralOptions))
  add(query_606236, "Version", newJString(Version))
  result = call_606235.call(nil, query_606236, nil, nil, nil)

var getDefineIndexField* = Call_GetDefineIndexField_606215(
    name: "getDefineIndexField", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineIndexField",
    validator: validate_GetDefineIndexField_606216, base: "/",
    url: url_GetDefineIndexField_606217, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDefineRankExpression_606278 = ref object of OpenApiRestCall_605589
proc url_PostDefineRankExpression_606280(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDefineRankExpression_606279(path: JsonNode; query: JsonNode;
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
  var valid_606281 = query.getOrDefault("Action")
  valid_606281 = validateParameter(valid_606281, JString, required = true,
                                 default = newJString("DefineRankExpression"))
  if valid_606281 != nil:
    section.add "Action", valid_606281
  var valid_606282 = query.getOrDefault("Version")
  valid_606282 = validateParameter(valid_606282, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_606282 != nil:
    section.add "Version", valid_606282
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606283 = header.getOrDefault("X-Amz-Signature")
  valid_606283 = validateParameter(valid_606283, JString, required = false,
                                 default = nil)
  if valid_606283 != nil:
    section.add "X-Amz-Signature", valid_606283
  var valid_606284 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606284 = validateParameter(valid_606284, JString, required = false,
                                 default = nil)
  if valid_606284 != nil:
    section.add "X-Amz-Content-Sha256", valid_606284
  var valid_606285 = header.getOrDefault("X-Amz-Date")
  valid_606285 = validateParameter(valid_606285, JString, required = false,
                                 default = nil)
  if valid_606285 != nil:
    section.add "X-Amz-Date", valid_606285
  var valid_606286 = header.getOrDefault("X-Amz-Credential")
  valid_606286 = validateParameter(valid_606286, JString, required = false,
                                 default = nil)
  if valid_606286 != nil:
    section.add "X-Amz-Credential", valid_606286
  var valid_606287 = header.getOrDefault("X-Amz-Security-Token")
  valid_606287 = validateParameter(valid_606287, JString, required = false,
                                 default = nil)
  if valid_606287 != nil:
    section.add "X-Amz-Security-Token", valid_606287
  var valid_606288 = header.getOrDefault("X-Amz-Algorithm")
  valid_606288 = validateParameter(valid_606288, JString, required = false,
                                 default = nil)
  if valid_606288 != nil:
    section.add "X-Amz-Algorithm", valid_606288
  var valid_606289 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606289 = validateParameter(valid_606289, JString, required = false,
                                 default = nil)
  if valid_606289 != nil:
    section.add "X-Amz-SignedHeaders", valid_606289
  result.add "header", section
  ## parameters in `formData` object:
  ##   RankExpression.RankName: JString
  ##                          : A named expression that can be evaluated at search time and used for ranking or thresholding in a search query. 
  ## The name of a rank expression. Rank expression names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   RankExpression.RankExpression: JString
  ##                                : A named expression that can be evaluated at search time and used for ranking or thresholding in a search query. 
  ## <p>The expression to evaluate for ranking or thresholding while processing a search request. The <code>RankExpression</code> syntax is based on JavaScript expressions and supports:</p> <ul> <li>Integer, floating point, hex and octal literals</li> <li>Shortcut evaluation of logical operators such that an expression <code>a || b</code> evaluates to the value <code>a</code>, if <code>a</code> is true, without evaluating <code>b</code> at all</li> <li>JavaScript order of precedence for operators</li> <li>Arithmetic operators: <code>+ - * / %</code> </li> <li>Boolean operators (including the ternary operator)</li> <li>Bitwise operators</li> <li>Comparison operators</li> <li>Common mathematic functions: <code>abs ceil erf exp floor lgamma ln log2 log10 max min sqrt pow</code> </li> <li>Trigonometric library functions: <code>acosh acos asinh asin atanh atan cosh cos sinh sin tanh tan</code> </li> <li>Random generation of a number between 0 and 1: <code>rand</code> </li> <li>Current time in epoch: <code>time</code> </li> <li>The <code>min max</code> functions that operate on a variable argument list</li> </ul> <p>Intermediate results are calculated as double precision floating point values. The final return value of a <code>RankExpression</code> is automatically converted from floating point to a 32-bit unsigned integer by rounding to the nearest integer, with a natural floor of 0 and a ceiling of max(uint32_t), 4294967295. Mathematical errors such as dividing by 0 will fail during evaluation and return a value of 0.</p> <p>The source data for a <code>RankExpression</code> can be the name of an <code>IndexField</code> of type uint, another <code>RankExpression</code> or the reserved name <i>text_relevance</i>. The text_relevance source is defined to return an integer from 0 to 1000 (inclusive) to indicate how relevant a document is to the search request, taking into account repetition of search terms in the document and proximity of search terms to each other in each matching <code>IndexField</code> in the document.</p> <p>For more information about using rank expressions to customize ranking, see the Amazon CloudSearch Developer Guide.</p>
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  var valid_606290 = formData.getOrDefault("RankExpression.RankName")
  valid_606290 = validateParameter(valid_606290, JString, required = false,
                                 default = nil)
  if valid_606290 != nil:
    section.add "RankExpression.RankName", valid_606290
  var valid_606291 = formData.getOrDefault("RankExpression.RankExpression")
  valid_606291 = validateParameter(valid_606291, JString, required = false,
                                 default = nil)
  if valid_606291 != nil:
    section.add "RankExpression.RankExpression", valid_606291
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_606292 = formData.getOrDefault("DomainName")
  valid_606292 = validateParameter(valid_606292, JString, required = true,
                                 default = nil)
  if valid_606292 != nil:
    section.add "DomainName", valid_606292
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606293: Call_PostDefineRankExpression_606278; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a <code>RankExpression</code> for the search domain. Used to create new rank expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. You can configure a maximum of 50 rank expressions.
  ## 
  let valid = call_606293.validator(path, query, header, formData, body)
  let scheme = call_606293.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606293.url(scheme.get, call_606293.host, call_606293.base,
                         call_606293.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606293, url, valid)

proc call*(call_606294: Call_PostDefineRankExpression_606278; DomainName: string;
          RankExpressionRankName: string = "";
          RankExpressionRankExpression: string = "";
          Action: string = "DefineRankExpression"; Version: string = "2011-02-01"): Recallable =
  ## postDefineRankExpression
  ## Configures a <code>RankExpression</code> for the search domain. Used to create new rank expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. You can configure a maximum of 50 rank expressions.
  ##   RankExpressionRankName: string
  ##                         : A named expression that can be evaluated at search time and used for ranking or thresholding in a search query. 
  ## The name of a rank expression. Rank expression names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   RankExpressionRankExpression: string
  ##                               : A named expression that can be evaluated at search time and used for ranking or thresholding in a search query. 
  ## <p>The expression to evaluate for ranking or thresholding while processing a search request. The <code>RankExpression</code> syntax is based on JavaScript expressions and supports:</p> <ul> <li>Integer, floating point, hex and octal literals</li> <li>Shortcut evaluation of logical operators such that an expression <code>a || b</code> evaluates to the value <code>a</code>, if <code>a</code> is true, without evaluating <code>b</code> at all</li> <li>JavaScript order of precedence for operators</li> <li>Arithmetic operators: <code>+ - * / %</code> </li> <li>Boolean operators (including the ternary operator)</li> <li>Bitwise operators</li> <li>Comparison operators</li> <li>Common mathematic functions: <code>abs ceil erf exp floor lgamma ln log2 log10 max min sqrt pow</code> </li> <li>Trigonometric library functions: <code>acosh acos asinh asin atanh atan cosh cos sinh sin tanh tan</code> </li> <li>Random generation of a number between 0 and 1: <code>rand</code> </li> <li>Current time in epoch: <code>time</code> </li> <li>The <code>min max</code> functions that operate on a variable argument list</li> </ul> <p>Intermediate results are calculated as double precision floating point values. The final return value of a <code>RankExpression</code> is automatically converted from floating point to a 32-bit unsigned integer by rounding to the nearest integer, with a natural floor of 0 and a ceiling of max(uint32_t), 4294967295. Mathematical errors such as dividing by 0 will fail during evaluation and return a value of 0.</p> <p>The source data for a <code>RankExpression</code> can be the name of an <code>IndexField</code> of type uint, another <code>RankExpression</code> or the reserved name <i>text_relevance</i>. The text_relevance source is defined to return an integer from 0 to 1000 (inclusive) to indicate how relevant a document is to the search request, taking into account repetition of search terms in the document and proximity of search terms to each other in each matching <code>IndexField</code> in the document.</p> <p>For more information about using rank expressions to customize ranking, see the Amazon CloudSearch Developer Guide.</p>
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606295 = newJObject()
  var formData_606296 = newJObject()
  add(formData_606296, "RankExpression.RankName",
      newJString(RankExpressionRankName))
  add(formData_606296, "RankExpression.RankExpression",
      newJString(RankExpressionRankExpression))
  add(formData_606296, "DomainName", newJString(DomainName))
  add(query_606295, "Action", newJString(Action))
  add(query_606295, "Version", newJString(Version))
  result = call_606294.call(nil, query_606295, nil, formData_606296, nil)

var postDefineRankExpression* = Call_PostDefineRankExpression_606278(
    name: "postDefineRankExpression", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineRankExpression",
    validator: validate_PostDefineRankExpression_606279, base: "/",
    url: url_PostDefineRankExpression_606280, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDefineRankExpression_606260 = ref object of OpenApiRestCall_605589
proc url_GetDefineRankExpression_606262(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDefineRankExpression_606261(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures a <code>RankExpression</code> for the search domain. Used to create new rank expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. You can configure a maximum of 50 rank expressions.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   RankExpression.RankName: JString
  ##                          : A named expression that can be evaluated at search time and used for ranking or thresholding in a search query. 
  ## The name of a rank expression. Rank expression names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   RankExpression.RankExpression: JString
  ##                                : A named expression that can be evaluated at search time and used for ranking or thresholding in a search query. 
  ## <p>The expression to evaluate for ranking or thresholding while processing a search request. The <code>RankExpression</code> syntax is based on JavaScript expressions and supports:</p> <ul> <li>Integer, floating point, hex and octal literals</li> <li>Shortcut evaluation of logical operators such that an expression <code>a || b</code> evaluates to the value <code>a</code>, if <code>a</code> is true, without evaluating <code>b</code> at all</li> <li>JavaScript order of precedence for operators</li> <li>Arithmetic operators: <code>+ - * / %</code> </li> <li>Boolean operators (including the ternary operator)</li> <li>Bitwise operators</li> <li>Comparison operators</li> <li>Common mathematic functions: <code>abs ceil erf exp floor lgamma ln log2 log10 max min sqrt pow</code> </li> <li>Trigonometric library functions: <code>acosh acos asinh asin atanh atan cosh cos sinh sin tanh tan</code> </li> <li>Random generation of a number between 0 and 1: <code>rand</code> </li> <li>Current time in epoch: <code>time</code> </li> <li>The <code>min max</code> functions that operate on a variable argument list</li> </ul> <p>Intermediate results are calculated as double precision floating point values. The final return value of a <code>RankExpression</code> is automatically converted from floating point to a 32-bit unsigned integer by rounding to the nearest integer, with a natural floor of 0 and a ceiling of max(uint32_t), 4294967295. Mathematical errors such as dividing by 0 will fail during evaluation and return a value of 0.</p> <p>The source data for a <code>RankExpression</code> can be the name of an <code>IndexField</code> of type uint, another <code>RankExpression</code> or the reserved name <i>text_relevance</i>. The text_relevance source is defined to return an integer from 0 to 1000 (inclusive) to indicate how relevant a document is to the search request, taking into account repetition of search terms in the document and proximity of search terms to each other in each matching <code>IndexField</code> in the document.</p> <p>For more information about using rank expressions to customize ranking, see the Amazon CloudSearch Developer Guide.</p>
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_606263 = query.getOrDefault("DomainName")
  valid_606263 = validateParameter(valid_606263, JString, required = true,
                                 default = nil)
  if valid_606263 != nil:
    section.add "DomainName", valid_606263
  var valid_606264 = query.getOrDefault("Action")
  valid_606264 = validateParameter(valid_606264, JString, required = true,
                                 default = newJString("DefineRankExpression"))
  if valid_606264 != nil:
    section.add "Action", valid_606264
  var valid_606265 = query.getOrDefault("Version")
  valid_606265 = validateParameter(valid_606265, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_606265 != nil:
    section.add "Version", valid_606265
  var valid_606266 = query.getOrDefault("RankExpression.RankName")
  valid_606266 = validateParameter(valid_606266, JString, required = false,
                                 default = nil)
  if valid_606266 != nil:
    section.add "RankExpression.RankName", valid_606266
  var valid_606267 = query.getOrDefault("RankExpression.RankExpression")
  valid_606267 = validateParameter(valid_606267, JString, required = false,
                                 default = nil)
  if valid_606267 != nil:
    section.add "RankExpression.RankExpression", valid_606267
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606268 = header.getOrDefault("X-Amz-Signature")
  valid_606268 = validateParameter(valid_606268, JString, required = false,
                                 default = nil)
  if valid_606268 != nil:
    section.add "X-Amz-Signature", valid_606268
  var valid_606269 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606269 = validateParameter(valid_606269, JString, required = false,
                                 default = nil)
  if valid_606269 != nil:
    section.add "X-Amz-Content-Sha256", valid_606269
  var valid_606270 = header.getOrDefault("X-Amz-Date")
  valid_606270 = validateParameter(valid_606270, JString, required = false,
                                 default = nil)
  if valid_606270 != nil:
    section.add "X-Amz-Date", valid_606270
  var valid_606271 = header.getOrDefault("X-Amz-Credential")
  valid_606271 = validateParameter(valid_606271, JString, required = false,
                                 default = nil)
  if valid_606271 != nil:
    section.add "X-Amz-Credential", valid_606271
  var valid_606272 = header.getOrDefault("X-Amz-Security-Token")
  valid_606272 = validateParameter(valid_606272, JString, required = false,
                                 default = nil)
  if valid_606272 != nil:
    section.add "X-Amz-Security-Token", valid_606272
  var valid_606273 = header.getOrDefault("X-Amz-Algorithm")
  valid_606273 = validateParameter(valid_606273, JString, required = false,
                                 default = nil)
  if valid_606273 != nil:
    section.add "X-Amz-Algorithm", valid_606273
  var valid_606274 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606274 = validateParameter(valid_606274, JString, required = false,
                                 default = nil)
  if valid_606274 != nil:
    section.add "X-Amz-SignedHeaders", valid_606274
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606275: Call_GetDefineRankExpression_606260; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a <code>RankExpression</code> for the search domain. Used to create new rank expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. You can configure a maximum of 50 rank expressions.
  ## 
  let valid = call_606275.validator(path, query, header, formData, body)
  let scheme = call_606275.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606275.url(scheme.get, call_606275.host, call_606275.base,
                         call_606275.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606275, url, valid)

proc call*(call_606276: Call_GetDefineRankExpression_606260; DomainName: string;
          Action: string = "DefineRankExpression"; Version: string = "2011-02-01";
          RankExpressionRankName: string = "";
          RankExpressionRankExpression: string = ""): Recallable =
  ## getDefineRankExpression
  ## Configures a <code>RankExpression</code> for the search domain. Used to create new rank expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. You can configure a maximum of 50 rank expressions.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   RankExpressionRankName: string
  ##                         : A named expression that can be evaluated at search time and used for ranking or thresholding in a search query. 
  ## The name of a rank expression. Rank expression names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   RankExpressionRankExpression: string
  ##                               : A named expression that can be evaluated at search time and used for ranking or thresholding in a search query. 
  ## <p>The expression to evaluate for ranking or thresholding while processing a search request. The <code>RankExpression</code> syntax is based on JavaScript expressions and supports:</p> <ul> <li>Integer, floating point, hex and octal literals</li> <li>Shortcut evaluation of logical operators such that an expression <code>a || b</code> evaluates to the value <code>a</code>, if <code>a</code> is true, without evaluating <code>b</code> at all</li> <li>JavaScript order of precedence for operators</li> <li>Arithmetic operators: <code>+ - * / %</code> </li> <li>Boolean operators (including the ternary operator)</li> <li>Bitwise operators</li> <li>Comparison operators</li> <li>Common mathematic functions: <code>abs ceil erf exp floor lgamma ln log2 log10 max min sqrt pow</code> </li> <li>Trigonometric library functions: <code>acosh acos asinh asin atanh atan cosh cos sinh sin tanh tan</code> </li> <li>Random generation of a number between 0 and 1: <code>rand</code> </li> <li>Current time in epoch: <code>time</code> </li> <li>The <code>min max</code> functions that operate on a variable argument list</li> </ul> <p>Intermediate results are calculated as double precision floating point values. The final return value of a <code>RankExpression</code> is automatically converted from floating point to a 32-bit unsigned integer by rounding to the nearest integer, with a natural floor of 0 and a ceiling of max(uint32_t), 4294967295. Mathematical errors such as dividing by 0 will fail during evaluation and return a value of 0.</p> <p>The source data for a <code>RankExpression</code> can be the name of an <code>IndexField</code> of type uint, another <code>RankExpression</code> or the reserved name <i>text_relevance</i>. The text_relevance source is defined to return an integer from 0 to 1000 (inclusive) to indicate how relevant a document is to the search request, taking into account repetition of search terms in the document and proximity of search terms to each other in each matching <code>IndexField</code> in the document.</p> <p>For more information about using rank expressions to customize ranking, see the Amazon CloudSearch Developer Guide.</p>
  var query_606277 = newJObject()
  add(query_606277, "DomainName", newJString(DomainName))
  add(query_606277, "Action", newJString(Action))
  add(query_606277, "Version", newJString(Version))
  add(query_606277, "RankExpression.RankName", newJString(RankExpressionRankName))
  add(query_606277, "RankExpression.RankExpression",
      newJString(RankExpressionRankExpression))
  result = call_606276.call(nil, query_606277, nil, nil, nil)

var getDefineRankExpression* = Call_GetDefineRankExpression_606260(
    name: "getDefineRankExpression", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineRankExpression",
    validator: validate_GetDefineRankExpression_606261, base: "/",
    url: url_GetDefineRankExpression_606262, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDomain_606313 = ref object of OpenApiRestCall_605589
proc url_PostDeleteDomain_606315(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDomain_606314(path: JsonNode; query: JsonNode;
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
  var valid_606316 = query.getOrDefault("Action")
  valid_606316 = validateParameter(valid_606316, JString, required = true,
                                 default = newJString("DeleteDomain"))
  if valid_606316 != nil:
    section.add "Action", valid_606316
  var valid_606317 = query.getOrDefault("Version")
  valid_606317 = validateParameter(valid_606317, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_606317 != nil:
    section.add "Version", valid_606317
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606318 = header.getOrDefault("X-Amz-Signature")
  valid_606318 = validateParameter(valid_606318, JString, required = false,
                                 default = nil)
  if valid_606318 != nil:
    section.add "X-Amz-Signature", valid_606318
  var valid_606319 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606319 = validateParameter(valid_606319, JString, required = false,
                                 default = nil)
  if valid_606319 != nil:
    section.add "X-Amz-Content-Sha256", valid_606319
  var valid_606320 = header.getOrDefault("X-Amz-Date")
  valid_606320 = validateParameter(valid_606320, JString, required = false,
                                 default = nil)
  if valid_606320 != nil:
    section.add "X-Amz-Date", valid_606320
  var valid_606321 = header.getOrDefault("X-Amz-Credential")
  valid_606321 = validateParameter(valid_606321, JString, required = false,
                                 default = nil)
  if valid_606321 != nil:
    section.add "X-Amz-Credential", valid_606321
  var valid_606322 = header.getOrDefault("X-Amz-Security-Token")
  valid_606322 = validateParameter(valid_606322, JString, required = false,
                                 default = nil)
  if valid_606322 != nil:
    section.add "X-Amz-Security-Token", valid_606322
  var valid_606323 = header.getOrDefault("X-Amz-Algorithm")
  valid_606323 = validateParameter(valid_606323, JString, required = false,
                                 default = nil)
  if valid_606323 != nil:
    section.add "X-Amz-Algorithm", valid_606323
  var valid_606324 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606324 = validateParameter(valid_606324, JString, required = false,
                                 default = nil)
  if valid_606324 != nil:
    section.add "X-Amz-SignedHeaders", valid_606324
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_606325 = formData.getOrDefault("DomainName")
  valid_606325 = validateParameter(valid_606325, JString, required = true,
                                 default = nil)
  if valid_606325 != nil:
    section.add "DomainName", valid_606325
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606326: Call_PostDeleteDomain_606313; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently deletes a search domain and all of its data.
  ## 
  let valid = call_606326.validator(path, query, header, formData, body)
  let scheme = call_606326.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606326.url(scheme.get, call_606326.host, call_606326.base,
                         call_606326.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606326, url, valid)

proc call*(call_606327: Call_PostDeleteDomain_606313; DomainName: string;
          Action: string = "DeleteDomain"; Version: string = "2011-02-01"): Recallable =
  ## postDeleteDomain
  ## Permanently deletes a search domain and all of its data.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606328 = newJObject()
  var formData_606329 = newJObject()
  add(formData_606329, "DomainName", newJString(DomainName))
  add(query_606328, "Action", newJString(Action))
  add(query_606328, "Version", newJString(Version))
  result = call_606327.call(nil, query_606328, nil, formData_606329, nil)

var postDeleteDomain* = Call_PostDeleteDomain_606313(name: "postDeleteDomain",
    meth: HttpMethod.HttpPost, host: "cloudsearch.amazonaws.com",
    route: "/#Action=DeleteDomain", validator: validate_PostDeleteDomain_606314,
    base: "/", url: url_PostDeleteDomain_606315,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDomain_606297 = ref object of OpenApiRestCall_605589
proc url_GetDeleteDomain_606299(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDomain_606298(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Permanently deletes a search domain and all of its data.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_606300 = query.getOrDefault("DomainName")
  valid_606300 = validateParameter(valid_606300, JString, required = true,
                                 default = nil)
  if valid_606300 != nil:
    section.add "DomainName", valid_606300
  var valid_606301 = query.getOrDefault("Action")
  valid_606301 = validateParameter(valid_606301, JString, required = true,
                                 default = newJString("DeleteDomain"))
  if valid_606301 != nil:
    section.add "Action", valid_606301
  var valid_606302 = query.getOrDefault("Version")
  valid_606302 = validateParameter(valid_606302, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_606302 != nil:
    section.add "Version", valid_606302
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606303 = header.getOrDefault("X-Amz-Signature")
  valid_606303 = validateParameter(valid_606303, JString, required = false,
                                 default = nil)
  if valid_606303 != nil:
    section.add "X-Amz-Signature", valid_606303
  var valid_606304 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606304 = validateParameter(valid_606304, JString, required = false,
                                 default = nil)
  if valid_606304 != nil:
    section.add "X-Amz-Content-Sha256", valid_606304
  var valid_606305 = header.getOrDefault("X-Amz-Date")
  valid_606305 = validateParameter(valid_606305, JString, required = false,
                                 default = nil)
  if valid_606305 != nil:
    section.add "X-Amz-Date", valid_606305
  var valid_606306 = header.getOrDefault("X-Amz-Credential")
  valid_606306 = validateParameter(valid_606306, JString, required = false,
                                 default = nil)
  if valid_606306 != nil:
    section.add "X-Amz-Credential", valid_606306
  var valid_606307 = header.getOrDefault("X-Amz-Security-Token")
  valid_606307 = validateParameter(valid_606307, JString, required = false,
                                 default = nil)
  if valid_606307 != nil:
    section.add "X-Amz-Security-Token", valid_606307
  var valid_606308 = header.getOrDefault("X-Amz-Algorithm")
  valid_606308 = validateParameter(valid_606308, JString, required = false,
                                 default = nil)
  if valid_606308 != nil:
    section.add "X-Amz-Algorithm", valid_606308
  var valid_606309 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606309 = validateParameter(valid_606309, JString, required = false,
                                 default = nil)
  if valid_606309 != nil:
    section.add "X-Amz-SignedHeaders", valid_606309
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606310: Call_GetDeleteDomain_606297; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Permanently deletes a search domain and all of its data.
  ## 
  let valid = call_606310.validator(path, query, header, formData, body)
  let scheme = call_606310.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606310.url(scheme.get, call_606310.host, call_606310.base,
                         call_606310.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606310, url, valid)

proc call*(call_606311: Call_GetDeleteDomain_606297; DomainName: string;
          Action: string = "DeleteDomain"; Version: string = "2011-02-01"): Recallable =
  ## getDeleteDomain
  ## Permanently deletes a search domain and all of its data.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606312 = newJObject()
  add(query_606312, "DomainName", newJString(DomainName))
  add(query_606312, "Action", newJString(Action))
  add(query_606312, "Version", newJString(Version))
  result = call_606311.call(nil, query_606312, nil, nil, nil)

var getDeleteDomain* = Call_GetDeleteDomain_606297(name: "getDeleteDomain",
    meth: HttpMethod.HttpGet, host: "cloudsearch.amazonaws.com",
    route: "/#Action=DeleteDomain", validator: validate_GetDeleteDomain_606298,
    base: "/", url: url_GetDeleteDomain_606299, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteIndexField_606347 = ref object of OpenApiRestCall_605589
proc url_PostDeleteIndexField_606349(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteIndexField_606348(path: JsonNode; query: JsonNode;
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
  var valid_606350 = query.getOrDefault("Action")
  valid_606350 = validateParameter(valid_606350, JString, required = true,
                                 default = newJString("DeleteIndexField"))
  if valid_606350 != nil:
    section.add "Action", valid_606350
  var valid_606351 = query.getOrDefault("Version")
  valid_606351 = validateParameter(valid_606351, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_606351 != nil:
    section.add "Version", valid_606351
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606352 = header.getOrDefault("X-Amz-Signature")
  valid_606352 = validateParameter(valid_606352, JString, required = false,
                                 default = nil)
  if valid_606352 != nil:
    section.add "X-Amz-Signature", valid_606352
  var valid_606353 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606353 = validateParameter(valid_606353, JString, required = false,
                                 default = nil)
  if valid_606353 != nil:
    section.add "X-Amz-Content-Sha256", valid_606353
  var valid_606354 = header.getOrDefault("X-Amz-Date")
  valid_606354 = validateParameter(valid_606354, JString, required = false,
                                 default = nil)
  if valid_606354 != nil:
    section.add "X-Amz-Date", valid_606354
  var valid_606355 = header.getOrDefault("X-Amz-Credential")
  valid_606355 = validateParameter(valid_606355, JString, required = false,
                                 default = nil)
  if valid_606355 != nil:
    section.add "X-Amz-Credential", valid_606355
  var valid_606356 = header.getOrDefault("X-Amz-Security-Token")
  valid_606356 = validateParameter(valid_606356, JString, required = false,
                                 default = nil)
  if valid_606356 != nil:
    section.add "X-Amz-Security-Token", valid_606356
  var valid_606357 = header.getOrDefault("X-Amz-Algorithm")
  valid_606357 = validateParameter(valid_606357, JString, required = false,
                                 default = nil)
  if valid_606357 != nil:
    section.add "X-Amz-Algorithm", valid_606357
  var valid_606358 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606358 = validateParameter(valid_606358, JString, required = false,
                                 default = nil)
  if valid_606358 != nil:
    section.add "X-Amz-SignedHeaders", valid_606358
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   IndexFieldName: JString (required)
  ##                 : A string that represents the name of an index field. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_606359 = formData.getOrDefault("DomainName")
  valid_606359 = validateParameter(valid_606359, JString, required = true,
                                 default = nil)
  if valid_606359 != nil:
    section.add "DomainName", valid_606359
  var valid_606360 = formData.getOrDefault("IndexFieldName")
  valid_606360 = validateParameter(valid_606360, JString, required = true,
                                 default = nil)
  if valid_606360 != nil:
    section.add "IndexFieldName", valid_606360
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606361: Call_PostDeleteIndexField_606347; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes an <code>IndexField</code> from the search domain.
  ## 
  let valid = call_606361.validator(path, query, header, formData, body)
  let scheme = call_606361.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606361.url(scheme.get, call_606361.host, call_606361.base,
                         call_606361.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606361, url, valid)

proc call*(call_606362: Call_PostDeleteIndexField_606347; DomainName: string;
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
  var query_606363 = newJObject()
  var formData_606364 = newJObject()
  add(formData_606364, "DomainName", newJString(DomainName))
  add(formData_606364, "IndexFieldName", newJString(IndexFieldName))
  add(query_606363, "Action", newJString(Action))
  add(query_606363, "Version", newJString(Version))
  result = call_606362.call(nil, query_606363, nil, formData_606364, nil)

var postDeleteIndexField* = Call_PostDeleteIndexField_606347(
    name: "postDeleteIndexField", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteIndexField",
    validator: validate_PostDeleteIndexField_606348, base: "/",
    url: url_PostDeleteIndexField_606349, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteIndexField_606330 = ref object of OpenApiRestCall_605589
proc url_GetDeleteIndexField_606332(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteIndexField_606331(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Removes an <code>IndexField</code> from the search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   IndexFieldName: JString (required)
  ##                 : A string that represents the name of an index field. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_606333 = query.getOrDefault("DomainName")
  valid_606333 = validateParameter(valid_606333, JString, required = true,
                                 default = nil)
  if valid_606333 != nil:
    section.add "DomainName", valid_606333
  var valid_606334 = query.getOrDefault("Action")
  valid_606334 = validateParameter(valid_606334, JString, required = true,
                                 default = newJString("DeleteIndexField"))
  if valid_606334 != nil:
    section.add "Action", valid_606334
  var valid_606335 = query.getOrDefault("IndexFieldName")
  valid_606335 = validateParameter(valid_606335, JString, required = true,
                                 default = nil)
  if valid_606335 != nil:
    section.add "IndexFieldName", valid_606335
  var valid_606336 = query.getOrDefault("Version")
  valid_606336 = validateParameter(valid_606336, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_606336 != nil:
    section.add "Version", valid_606336
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606337 = header.getOrDefault("X-Amz-Signature")
  valid_606337 = validateParameter(valid_606337, JString, required = false,
                                 default = nil)
  if valid_606337 != nil:
    section.add "X-Amz-Signature", valid_606337
  var valid_606338 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606338 = validateParameter(valid_606338, JString, required = false,
                                 default = nil)
  if valid_606338 != nil:
    section.add "X-Amz-Content-Sha256", valid_606338
  var valid_606339 = header.getOrDefault("X-Amz-Date")
  valid_606339 = validateParameter(valid_606339, JString, required = false,
                                 default = nil)
  if valid_606339 != nil:
    section.add "X-Amz-Date", valid_606339
  var valid_606340 = header.getOrDefault("X-Amz-Credential")
  valid_606340 = validateParameter(valid_606340, JString, required = false,
                                 default = nil)
  if valid_606340 != nil:
    section.add "X-Amz-Credential", valid_606340
  var valid_606341 = header.getOrDefault("X-Amz-Security-Token")
  valid_606341 = validateParameter(valid_606341, JString, required = false,
                                 default = nil)
  if valid_606341 != nil:
    section.add "X-Amz-Security-Token", valid_606341
  var valid_606342 = header.getOrDefault("X-Amz-Algorithm")
  valid_606342 = validateParameter(valid_606342, JString, required = false,
                                 default = nil)
  if valid_606342 != nil:
    section.add "X-Amz-Algorithm", valid_606342
  var valid_606343 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606343 = validateParameter(valid_606343, JString, required = false,
                                 default = nil)
  if valid_606343 != nil:
    section.add "X-Amz-SignedHeaders", valid_606343
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606344: Call_GetDeleteIndexField_606330; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes an <code>IndexField</code> from the search domain.
  ## 
  let valid = call_606344.validator(path, query, header, formData, body)
  let scheme = call_606344.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606344.url(scheme.get, call_606344.host, call_606344.base,
                         call_606344.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606344, url, valid)

proc call*(call_606345: Call_GetDeleteIndexField_606330; DomainName: string;
          IndexFieldName: string; Action: string = "DeleteIndexField";
          Version: string = "2011-02-01"): Recallable =
  ## getDeleteIndexField
  ## Removes an <code>IndexField</code> from the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   IndexFieldName: string (required)
  ##                 : A string that represents the name of an index field. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   Version: string (required)
  var query_606346 = newJObject()
  add(query_606346, "DomainName", newJString(DomainName))
  add(query_606346, "Action", newJString(Action))
  add(query_606346, "IndexFieldName", newJString(IndexFieldName))
  add(query_606346, "Version", newJString(Version))
  result = call_606345.call(nil, query_606346, nil, nil, nil)

var getDeleteIndexField* = Call_GetDeleteIndexField_606330(
    name: "getDeleteIndexField", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteIndexField",
    validator: validate_GetDeleteIndexField_606331, base: "/",
    url: url_GetDeleteIndexField_606332, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteRankExpression_606382 = ref object of OpenApiRestCall_605589
proc url_PostDeleteRankExpression_606384(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteRankExpression_606383(path: JsonNode; query: JsonNode;
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
  var valid_606385 = query.getOrDefault("Action")
  valid_606385 = validateParameter(valid_606385, JString, required = true,
                                 default = newJString("DeleteRankExpression"))
  if valid_606385 != nil:
    section.add "Action", valid_606385
  var valid_606386 = query.getOrDefault("Version")
  valid_606386 = validateParameter(valid_606386, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_606386 != nil:
    section.add "Version", valid_606386
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606387 = header.getOrDefault("X-Amz-Signature")
  valid_606387 = validateParameter(valid_606387, JString, required = false,
                                 default = nil)
  if valid_606387 != nil:
    section.add "X-Amz-Signature", valid_606387
  var valid_606388 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606388 = validateParameter(valid_606388, JString, required = false,
                                 default = nil)
  if valid_606388 != nil:
    section.add "X-Amz-Content-Sha256", valid_606388
  var valid_606389 = header.getOrDefault("X-Amz-Date")
  valid_606389 = validateParameter(valid_606389, JString, required = false,
                                 default = nil)
  if valid_606389 != nil:
    section.add "X-Amz-Date", valid_606389
  var valid_606390 = header.getOrDefault("X-Amz-Credential")
  valid_606390 = validateParameter(valid_606390, JString, required = false,
                                 default = nil)
  if valid_606390 != nil:
    section.add "X-Amz-Credential", valid_606390
  var valid_606391 = header.getOrDefault("X-Amz-Security-Token")
  valid_606391 = validateParameter(valid_606391, JString, required = false,
                                 default = nil)
  if valid_606391 != nil:
    section.add "X-Amz-Security-Token", valid_606391
  var valid_606392 = header.getOrDefault("X-Amz-Algorithm")
  valid_606392 = validateParameter(valid_606392, JString, required = false,
                                 default = nil)
  if valid_606392 != nil:
    section.add "X-Amz-Algorithm", valid_606392
  var valid_606393 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606393 = validateParameter(valid_606393, JString, required = false,
                                 default = nil)
  if valid_606393 != nil:
    section.add "X-Amz-SignedHeaders", valid_606393
  result.add "header", section
  ## parameters in `formData` object:
  ##   RankName: JString (required)
  ##           : A string that represents the name of an index field. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `RankName` field"
  var valid_606394 = formData.getOrDefault("RankName")
  valid_606394 = validateParameter(valid_606394, JString, required = true,
                                 default = nil)
  if valid_606394 != nil:
    section.add "RankName", valid_606394
  var valid_606395 = formData.getOrDefault("DomainName")
  valid_606395 = validateParameter(valid_606395, JString, required = true,
                                 default = nil)
  if valid_606395 != nil:
    section.add "DomainName", valid_606395
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606396: Call_PostDeleteRankExpression_606382; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a <code>RankExpression</code> from the search domain.
  ## 
  let valid = call_606396.validator(path, query, header, formData, body)
  let scheme = call_606396.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606396.url(scheme.get, call_606396.host, call_606396.base,
                         call_606396.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606396, url, valid)

proc call*(call_606397: Call_PostDeleteRankExpression_606382; RankName: string;
          DomainName: string; Action: string = "DeleteRankExpression";
          Version: string = "2011-02-01"): Recallable =
  ## postDeleteRankExpression
  ## Removes a <code>RankExpression</code> from the search domain.
  ##   RankName: string (required)
  ##           : A string that represents the name of an index field. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606398 = newJObject()
  var formData_606399 = newJObject()
  add(formData_606399, "RankName", newJString(RankName))
  add(formData_606399, "DomainName", newJString(DomainName))
  add(query_606398, "Action", newJString(Action))
  add(query_606398, "Version", newJString(Version))
  result = call_606397.call(nil, query_606398, nil, formData_606399, nil)

var postDeleteRankExpression* = Call_PostDeleteRankExpression_606382(
    name: "postDeleteRankExpression", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteRankExpression",
    validator: validate_PostDeleteRankExpression_606383, base: "/",
    url: url_PostDeleteRankExpression_606384, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteRankExpression_606365 = ref object of OpenApiRestCall_605589
proc url_GetDeleteRankExpression_606367(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteRankExpression_606366(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Removes a <code>RankExpression</code> from the search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   RankName: JString (required)
  ##           : A string that represents the name of an index field. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_606368 = query.getOrDefault("DomainName")
  valid_606368 = validateParameter(valid_606368, JString, required = true,
                                 default = nil)
  if valid_606368 != nil:
    section.add "DomainName", valid_606368
  var valid_606369 = query.getOrDefault("RankName")
  valid_606369 = validateParameter(valid_606369, JString, required = true,
                                 default = nil)
  if valid_606369 != nil:
    section.add "RankName", valid_606369
  var valid_606370 = query.getOrDefault("Action")
  valid_606370 = validateParameter(valid_606370, JString, required = true,
                                 default = newJString("DeleteRankExpression"))
  if valid_606370 != nil:
    section.add "Action", valid_606370
  var valid_606371 = query.getOrDefault("Version")
  valid_606371 = validateParameter(valid_606371, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_606371 != nil:
    section.add "Version", valid_606371
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606372 = header.getOrDefault("X-Amz-Signature")
  valid_606372 = validateParameter(valid_606372, JString, required = false,
                                 default = nil)
  if valid_606372 != nil:
    section.add "X-Amz-Signature", valid_606372
  var valid_606373 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606373 = validateParameter(valid_606373, JString, required = false,
                                 default = nil)
  if valid_606373 != nil:
    section.add "X-Amz-Content-Sha256", valid_606373
  var valid_606374 = header.getOrDefault("X-Amz-Date")
  valid_606374 = validateParameter(valid_606374, JString, required = false,
                                 default = nil)
  if valid_606374 != nil:
    section.add "X-Amz-Date", valid_606374
  var valid_606375 = header.getOrDefault("X-Amz-Credential")
  valid_606375 = validateParameter(valid_606375, JString, required = false,
                                 default = nil)
  if valid_606375 != nil:
    section.add "X-Amz-Credential", valid_606375
  var valid_606376 = header.getOrDefault("X-Amz-Security-Token")
  valid_606376 = validateParameter(valid_606376, JString, required = false,
                                 default = nil)
  if valid_606376 != nil:
    section.add "X-Amz-Security-Token", valid_606376
  var valid_606377 = header.getOrDefault("X-Amz-Algorithm")
  valid_606377 = validateParameter(valid_606377, JString, required = false,
                                 default = nil)
  if valid_606377 != nil:
    section.add "X-Amz-Algorithm", valid_606377
  var valid_606378 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606378 = validateParameter(valid_606378, JString, required = false,
                                 default = nil)
  if valid_606378 != nil:
    section.add "X-Amz-SignedHeaders", valid_606378
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606379: Call_GetDeleteRankExpression_606365; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes a <code>RankExpression</code> from the search domain.
  ## 
  let valid = call_606379.validator(path, query, header, formData, body)
  let scheme = call_606379.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606379.url(scheme.get, call_606379.host, call_606379.base,
                         call_606379.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606379, url, valid)

proc call*(call_606380: Call_GetDeleteRankExpression_606365; DomainName: string;
          RankName: string; Action: string = "DeleteRankExpression";
          Version: string = "2011-02-01"): Recallable =
  ## getDeleteRankExpression
  ## Removes a <code>RankExpression</code> from the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   RankName: string (required)
  ##           : A string that represents the name of an index field. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606381 = newJObject()
  add(query_606381, "DomainName", newJString(DomainName))
  add(query_606381, "RankName", newJString(RankName))
  add(query_606381, "Action", newJString(Action))
  add(query_606381, "Version", newJString(Version))
  result = call_606380.call(nil, query_606381, nil, nil, nil)

var getDeleteRankExpression* = Call_GetDeleteRankExpression_606365(
    name: "getDeleteRankExpression", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteRankExpression",
    validator: validate_GetDeleteRankExpression_606366, base: "/",
    url: url_GetDeleteRankExpression_606367, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAvailabilityOptions_606416 = ref object of OpenApiRestCall_605589
proc url_PostDescribeAvailabilityOptions_606418(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeAvailabilityOptions_606417(path: JsonNode;
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
  var valid_606419 = query.getOrDefault("Action")
  valid_606419 = validateParameter(valid_606419, JString, required = true, default = newJString(
      "DescribeAvailabilityOptions"))
  if valid_606419 != nil:
    section.add "Action", valid_606419
  var valid_606420 = query.getOrDefault("Version")
  valid_606420 = validateParameter(valid_606420, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_606420 != nil:
    section.add "Version", valid_606420
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606421 = header.getOrDefault("X-Amz-Signature")
  valid_606421 = validateParameter(valid_606421, JString, required = false,
                                 default = nil)
  if valid_606421 != nil:
    section.add "X-Amz-Signature", valid_606421
  var valid_606422 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606422 = validateParameter(valid_606422, JString, required = false,
                                 default = nil)
  if valid_606422 != nil:
    section.add "X-Amz-Content-Sha256", valid_606422
  var valid_606423 = header.getOrDefault("X-Amz-Date")
  valid_606423 = validateParameter(valid_606423, JString, required = false,
                                 default = nil)
  if valid_606423 != nil:
    section.add "X-Amz-Date", valid_606423
  var valid_606424 = header.getOrDefault("X-Amz-Credential")
  valid_606424 = validateParameter(valid_606424, JString, required = false,
                                 default = nil)
  if valid_606424 != nil:
    section.add "X-Amz-Credential", valid_606424
  var valid_606425 = header.getOrDefault("X-Amz-Security-Token")
  valid_606425 = validateParameter(valid_606425, JString, required = false,
                                 default = nil)
  if valid_606425 != nil:
    section.add "X-Amz-Security-Token", valid_606425
  var valid_606426 = header.getOrDefault("X-Amz-Algorithm")
  valid_606426 = validateParameter(valid_606426, JString, required = false,
                                 default = nil)
  if valid_606426 != nil:
    section.add "X-Amz-Algorithm", valid_606426
  var valid_606427 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606427 = validateParameter(valid_606427, JString, required = false,
                                 default = nil)
  if valid_606427 != nil:
    section.add "X-Amz-SignedHeaders", valid_606427
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_606428 = formData.getOrDefault("DomainName")
  valid_606428 = validateParameter(valid_606428, JString, required = true,
                                 default = nil)
  if valid_606428 != nil:
    section.add "DomainName", valid_606428
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606429: Call_PostDescribeAvailabilityOptions_606416;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_606429.validator(path, query, header, formData, body)
  let scheme = call_606429.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606429.url(scheme.get, call_606429.host, call_606429.base,
                         call_606429.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606429, url, valid)

proc call*(call_606430: Call_PostDescribeAvailabilityOptions_606416;
          DomainName: string; Action: string = "DescribeAvailabilityOptions";
          Version: string = "2011-02-01"): Recallable =
  ## postDescribeAvailabilityOptions
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606431 = newJObject()
  var formData_606432 = newJObject()
  add(formData_606432, "DomainName", newJString(DomainName))
  add(query_606431, "Action", newJString(Action))
  add(query_606431, "Version", newJString(Version))
  result = call_606430.call(nil, query_606431, nil, formData_606432, nil)

var postDescribeAvailabilityOptions* = Call_PostDescribeAvailabilityOptions_606416(
    name: "postDescribeAvailabilityOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeAvailabilityOptions",
    validator: validate_PostDescribeAvailabilityOptions_606417, base: "/",
    url: url_PostDescribeAvailabilityOptions_606418,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAvailabilityOptions_606400 = ref object of OpenApiRestCall_605589
proc url_GetDescribeAvailabilityOptions_606402(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeAvailabilityOptions_606401(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_606403 = query.getOrDefault("DomainName")
  valid_606403 = validateParameter(valid_606403, JString, required = true,
                                 default = nil)
  if valid_606403 != nil:
    section.add "DomainName", valid_606403
  var valid_606404 = query.getOrDefault("Action")
  valid_606404 = validateParameter(valid_606404, JString, required = true, default = newJString(
      "DescribeAvailabilityOptions"))
  if valid_606404 != nil:
    section.add "Action", valid_606404
  var valid_606405 = query.getOrDefault("Version")
  valid_606405 = validateParameter(valid_606405, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_606405 != nil:
    section.add "Version", valid_606405
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606406 = header.getOrDefault("X-Amz-Signature")
  valid_606406 = validateParameter(valid_606406, JString, required = false,
                                 default = nil)
  if valid_606406 != nil:
    section.add "X-Amz-Signature", valid_606406
  var valid_606407 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606407 = validateParameter(valid_606407, JString, required = false,
                                 default = nil)
  if valid_606407 != nil:
    section.add "X-Amz-Content-Sha256", valid_606407
  var valid_606408 = header.getOrDefault("X-Amz-Date")
  valid_606408 = validateParameter(valid_606408, JString, required = false,
                                 default = nil)
  if valid_606408 != nil:
    section.add "X-Amz-Date", valid_606408
  var valid_606409 = header.getOrDefault("X-Amz-Credential")
  valid_606409 = validateParameter(valid_606409, JString, required = false,
                                 default = nil)
  if valid_606409 != nil:
    section.add "X-Amz-Credential", valid_606409
  var valid_606410 = header.getOrDefault("X-Amz-Security-Token")
  valid_606410 = validateParameter(valid_606410, JString, required = false,
                                 default = nil)
  if valid_606410 != nil:
    section.add "X-Amz-Security-Token", valid_606410
  var valid_606411 = header.getOrDefault("X-Amz-Algorithm")
  valid_606411 = validateParameter(valid_606411, JString, required = false,
                                 default = nil)
  if valid_606411 != nil:
    section.add "X-Amz-Algorithm", valid_606411
  var valid_606412 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606412 = validateParameter(valid_606412, JString, required = false,
                                 default = nil)
  if valid_606412 != nil:
    section.add "X-Amz-SignedHeaders", valid_606412
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606413: Call_GetDescribeAvailabilityOptions_606400; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_606413.validator(path, query, header, formData, body)
  let scheme = call_606413.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606413.url(scheme.get, call_606413.host, call_606413.base,
                         call_606413.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606413, url, valid)

proc call*(call_606414: Call_GetDescribeAvailabilityOptions_606400;
          DomainName: string; Action: string = "DescribeAvailabilityOptions";
          Version: string = "2011-02-01"): Recallable =
  ## getDescribeAvailabilityOptions
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606415 = newJObject()
  add(query_606415, "DomainName", newJString(DomainName))
  add(query_606415, "Action", newJString(Action))
  add(query_606415, "Version", newJString(Version))
  result = call_606414.call(nil, query_606415, nil, nil, nil)

var getDescribeAvailabilityOptions* = Call_GetDescribeAvailabilityOptions_606400(
    name: "getDescribeAvailabilityOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeAvailabilityOptions",
    validator: validate_GetDescribeAvailabilityOptions_606401, base: "/",
    url: url_GetDescribeAvailabilityOptions_606402,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDefaultSearchField_606449 = ref object of OpenApiRestCall_605589
proc url_PostDescribeDefaultSearchField_606451(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDefaultSearchField_606450(path: JsonNode;
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
  var valid_606452 = query.getOrDefault("Action")
  valid_606452 = validateParameter(valid_606452, JString, required = true, default = newJString(
      "DescribeDefaultSearchField"))
  if valid_606452 != nil:
    section.add "Action", valid_606452
  var valid_606453 = query.getOrDefault("Version")
  valid_606453 = validateParameter(valid_606453, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_606453 != nil:
    section.add "Version", valid_606453
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606454 = header.getOrDefault("X-Amz-Signature")
  valid_606454 = validateParameter(valid_606454, JString, required = false,
                                 default = nil)
  if valid_606454 != nil:
    section.add "X-Amz-Signature", valid_606454
  var valid_606455 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606455 = validateParameter(valid_606455, JString, required = false,
                                 default = nil)
  if valid_606455 != nil:
    section.add "X-Amz-Content-Sha256", valid_606455
  var valid_606456 = header.getOrDefault("X-Amz-Date")
  valid_606456 = validateParameter(valid_606456, JString, required = false,
                                 default = nil)
  if valid_606456 != nil:
    section.add "X-Amz-Date", valid_606456
  var valid_606457 = header.getOrDefault("X-Amz-Credential")
  valid_606457 = validateParameter(valid_606457, JString, required = false,
                                 default = nil)
  if valid_606457 != nil:
    section.add "X-Amz-Credential", valid_606457
  var valid_606458 = header.getOrDefault("X-Amz-Security-Token")
  valid_606458 = validateParameter(valid_606458, JString, required = false,
                                 default = nil)
  if valid_606458 != nil:
    section.add "X-Amz-Security-Token", valid_606458
  var valid_606459 = header.getOrDefault("X-Amz-Algorithm")
  valid_606459 = validateParameter(valid_606459, JString, required = false,
                                 default = nil)
  if valid_606459 != nil:
    section.add "X-Amz-Algorithm", valid_606459
  var valid_606460 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606460 = validateParameter(valid_606460, JString, required = false,
                                 default = nil)
  if valid_606460 != nil:
    section.add "X-Amz-SignedHeaders", valid_606460
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_606461 = formData.getOrDefault("DomainName")
  valid_606461 = validateParameter(valid_606461, JString, required = true,
                                 default = nil)
  if valid_606461 != nil:
    section.add "DomainName", valid_606461
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606462: Call_PostDescribeDefaultSearchField_606449; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the default search field configured for the search domain.
  ## 
  let valid = call_606462.validator(path, query, header, formData, body)
  let scheme = call_606462.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606462.url(scheme.get, call_606462.host, call_606462.base,
                         call_606462.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606462, url, valid)

proc call*(call_606463: Call_PostDescribeDefaultSearchField_606449;
          DomainName: string; Action: string = "DescribeDefaultSearchField";
          Version: string = "2011-02-01"): Recallable =
  ## postDescribeDefaultSearchField
  ## Gets the default search field configured for the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606464 = newJObject()
  var formData_606465 = newJObject()
  add(formData_606465, "DomainName", newJString(DomainName))
  add(query_606464, "Action", newJString(Action))
  add(query_606464, "Version", newJString(Version))
  result = call_606463.call(nil, query_606464, nil, formData_606465, nil)

var postDescribeDefaultSearchField* = Call_PostDescribeDefaultSearchField_606449(
    name: "postDescribeDefaultSearchField", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeDefaultSearchField",
    validator: validate_PostDescribeDefaultSearchField_606450, base: "/",
    url: url_PostDescribeDefaultSearchField_606451,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDefaultSearchField_606433 = ref object of OpenApiRestCall_605589
proc url_GetDescribeDefaultSearchField_606435(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDefaultSearchField_606434(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the default search field configured for the search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_606436 = query.getOrDefault("DomainName")
  valid_606436 = validateParameter(valid_606436, JString, required = true,
                                 default = nil)
  if valid_606436 != nil:
    section.add "DomainName", valid_606436
  var valid_606437 = query.getOrDefault("Action")
  valid_606437 = validateParameter(valid_606437, JString, required = true, default = newJString(
      "DescribeDefaultSearchField"))
  if valid_606437 != nil:
    section.add "Action", valid_606437
  var valid_606438 = query.getOrDefault("Version")
  valid_606438 = validateParameter(valid_606438, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_606438 != nil:
    section.add "Version", valid_606438
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606439 = header.getOrDefault("X-Amz-Signature")
  valid_606439 = validateParameter(valid_606439, JString, required = false,
                                 default = nil)
  if valid_606439 != nil:
    section.add "X-Amz-Signature", valid_606439
  var valid_606440 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606440 = validateParameter(valid_606440, JString, required = false,
                                 default = nil)
  if valid_606440 != nil:
    section.add "X-Amz-Content-Sha256", valid_606440
  var valid_606441 = header.getOrDefault("X-Amz-Date")
  valid_606441 = validateParameter(valid_606441, JString, required = false,
                                 default = nil)
  if valid_606441 != nil:
    section.add "X-Amz-Date", valid_606441
  var valid_606442 = header.getOrDefault("X-Amz-Credential")
  valid_606442 = validateParameter(valid_606442, JString, required = false,
                                 default = nil)
  if valid_606442 != nil:
    section.add "X-Amz-Credential", valid_606442
  var valid_606443 = header.getOrDefault("X-Amz-Security-Token")
  valid_606443 = validateParameter(valid_606443, JString, required = false,
                                 default = nil)
  if valid_606443 != nil:
    section.add "X-Amz-Security-Token", valid_606443
  var valid_606444 = header.getOrDefault("X-Amz-Algorithm")
  valid_606444 = validateParameter(valid_606444, JString, required = false,
                                 default = nil)
  if valid_606444 != nil:
    section.add "X-Amz-Algorithm", valid_606444
  var valid_606445 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606445 = validateParameter(valid_606445, JString, required = false,
                                 default = nil)
  if valid_606445 != nil:
    section.add "X-Amz-SignedHeaders", valid_606445
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606446: Call_GetDescribeDefaultSearchField_606433; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the default search field configured for the search domain.
  ## 
  let valid = call_606446.validator(path, query, header, formData, body)
  let scheme = call_606446.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606446.url(scheme.get, call_606446.host, call_606446.base,
                         call_606446.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606446, url, valid)

proc call*(call_606447: Call_GetDescribeDefaultSearchField_606433;
          DomainName: string; Action: string = "DescribeDefaultSearchField";
          Version: string = "2011-02-01"): Recallable =
  ## getDescribeDefaultSearchField
  ## Gets the default search field configured for the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606448 = newJObject()
  add(query_606448, "DomainName", newJString(DomainName))
  add(query_606448, "Action", newJString(Action))
  add(query_606448, "Version", newJString(Version))
  result = call_606447.call(nil, query_606448, nil, nil, nil)

var getDescribeDefaultSearchField* = Call_GetDescribeDefaultSearchField_606433(
    name: "getDescribeDefaultSearchField", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeDefaultSearchField",
    validator: validate_GetDescribeDefaultSearchField_606434, base: "/",
    url: url_GetDescribeDefaultSearchField_606435,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDomains_606482 = ref object of OpenApiRestCall_605589
proc url_PostDescribeDomains_606484(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDomains_606483(path: JsonNode; query: JsonNode;
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
  var valid_606485 = query.getOrDefault("Action")
  valid_606485 = validateParameter(valid_606485, JString, required = true,
                                 default = newJString("DescribeDomains"))
  if valid_606485 != nil:
    section.add "Action", valid_606485
  var valid_606486 = query.getOrDefault("Version")
  valid_606486 = validateParameter(valid_606486, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_606486 != nil:
    section.add "Version", valid_606486
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606487 = header.getOrDefault("X-Amz-Signature")
  valid_606487 = validateParameter(valid_606487, JString, required = false,
                                 default = nil)
  if valid_606487 != nil:
    section.add "X-Amz-Signature", valid_606487
  var valid_606488 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606488 = validateParameter(valid_606488, JString, required = false,
                                 default = nil)
  if valid_606488 != nil:
    section.add "X-Amz-Content-Sha256", valid_606488
  var valid_606489 = header.getOrDefault("X-Amz-Date")
  valid_606489 = validateParameter(valid_606489, JString, required = false,
                                 default = nil)
  if valid_606489 != nil:
    section.add "X-Amz-Date", valid_606489
  var valid_606490 = header.getOrDefault("X-Amz-Credential")
  valid_606490 = validateParameter(valid_606490, JString, required = false,
                                 default = nil)
  if valid_606490 != nil:
    section.add "X-Amz-Credential", valid_606490
  var valid_606491 = header.getOrDefault("X-Amz-Security-Token")
  valid_606491 = validateParameter(valid_606491, JString, required = false,
                                 default = nil)
  if valid_606491 != nil:
    section.add "X-Amz-Security-Token", valid_606491
  var valid_606492 = header.getOrDefault("X-Amz-Algorithm")
  valid_606492 = validateParameter(valid_606492, JString, required = false,
                                 default = nil)
  if valid_606492 != nil:
    section.add "X-Amz-Algorithm", valid_606492
  var valid_606493 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606493 = validateParameter(valid_606493, JString, required = false,
                                 default = nil)
  if valid_606493 != nil:
    section.add "X-Amz-SignedHeaders", valid_606493
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainNames: JArray
  ##              : A list of domain names.
  section = newJObject()
  var valid_606494 = formData.getOrDefault("DomainNames")
  valid_606494 = validateParameter(valid_606494, JArray, required = false,
                                 default = nil)
  if valid_606494 != nil:
    section.add "DomainNames", valid_606494
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606495: Call_PostDescribeDomains_606482; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default.
  ## 
  let valid = call_606495.validator(path, query, header, formData, body)
  let scheme = call_606495.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606495.url(scheme.get, call_606495.host, call_606495.base,
                         call_606495.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606495, url, valid)

proc call*(call_606496: Call_PostDescribeDomains_606482;
          DomainNames: JsonNode = nil; Action: string = "DescribeDomains";
          Version: string = "2011-02-01"): Recallable =
  ## postDescribeDomains
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default.
  ##   DomainNames: JArray
  ##              : A list of domain names.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606497 = newJObject()
  var formData_606498 = newJObject()
  if DomainNames != nil:
    formData_606498.add "DomainNames", DomainNames
  add(query_606497, "Action", newJString(Action))
  add(query_606497, "Version", newJString(Version))
  result = call_606496.call(nil, query_606497, nil, formData_606498, nil)

var postDescribeDomains* = Call_PostDescribeDomains_606482(
    name: "postDescribeDomains", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeDomains",
    validator: validate_PostDescribeDomains_606483, base: "/",
    url: url_PostDescribeDomains_606484, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDomains_606466 = ref object of OpenApiRestCall_605589
proc url_GetDescribeDomains_606468(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDomains_606467(path: JsonNode; query: JsonNode;
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
  var valid_606469 = query.getOrDefault("DomainNames")
  valid_606469 = validateParameter(valid_606469, JArray, required = false,
                                 default = nil)
  if valid_606469 != nil:
    section.add "DomainNames", valid_606469
  assert query != nil, "query argument is necessary due to required `Action` field"
  var valid_606470 = query.getOrDefault("Action")
  valid_606470 = validateParameter(valid_606470, JString, required = true,
                                 default = newJString("DescribeDomains"))
  if valid_606470 != nil:
    section.add "Action", valid_606470
  var valid_606471 = query.getOrDefault("Version")
  valid_606471 = validateParameter(valid_606471, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_606471 != nil:
    section.add "Version", valid_606471
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606472 = header.getOrDefault("X-Amz-Signature")
  valid_606472 = validateParameter(valid_606472, JString, required = false,
                                 default = nil)
  if valid_606472 != nil:
    section.add "X-Amz-Signature", valid_606472
  var valid_606473 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606473 = validateParameter(valid_606473, JString, required = false,
                                 default = nil)
  if valid_606473 != nil:
    section.add "X-Amz-Content-Sha256", valid_606473
  var valid_606474 = header.getOrDefault("X-Amz-Date")
  valid_606474 = validateParameter(valid_606474, JString, required = false,
                                 default = nil)
  if valid_606474 != nil:
    section.add "X-Amz-Date", valid_606474
  var valid_606475 = header.getOrDefault("X-Amz-Credential")
  valid_606475 = validateParameter(valid_606475, JString, required = false,
                                 default = nil)
  if valid_606475 != nil:
    section.add "X-Amz-Credential", valid_606475
  var valid_606476 = header.getOrDefault("X-Amz-Security-Token")
  valid_606476 = validateParameter(valid_606476, JString, required = false,
                                 default = nil)
  if valid_606476 != nil:
    section.add "X-Amz-Security-Token", valid_606476
  var valid_606477 = header.getOrDefault("X-Amz-Algorithm")
  valid_606477 = validateParameter(valid_606477, JString, required = false,
                                 default = nil)
  if valid_606477 != nil:
    section.add "X-Amz-Algorithm", valid_606477
  var valid_606478 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606478 = validateParameter(valid_606478, JString, required = false,
                                 default = nil)
  if valid_606478 != nil:
    section.add "X-Amz-SignedHeaders", valid_606478
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606479: Call_GetDescribeDomains_606466; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default.
  ## 
  let valid = call_606479.validator(path, query, header, formData, body)
  let scheme = call_606479.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606479.url(scheme.get, call_606479.host, call_606479.base,
                         call_606479.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606479, url, valid)

proc call*(call_606480: Call_GetDescribeDomains_606466;
          DomainNames: JsonNode = nil; Action: string = "DescribeDomains";
          Version: string = "2011-02-01"): Recallable =
  ## getDescribeDomains
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default.
  ##   DomainNames: JArray
  ##              : A list of domain names.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606481 = newJObject()
  if DomainNames != nil:
    query_606481.add "DomainNames", DomainNames
  add(query_606481, "Action", newJString(Action))
  add(query_606481, "Version", newJString(Version))
  result = call_606480.call(nil, query_606481, nil, nil, nil)

var getDescribeDomains* = Call_GetDescribeDomains_606466(
    name: "getDescribeDomains", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeDomains",
    validator: validate_GetDescribeDomains_606467, base: "/",
    url: url_GetDescribeDomains_606468, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeIndexFields_606516 = ref object of OpenApiRestCall_605589
proc url_PostDescribeIndexFields_606518(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeIndexFields_606517(path: JsonNode; query: JsonNode;
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
  var valid_606519 = query.getOrDefault("Action")
  valid_606519 = validateParameter(valid_606519, JString, required = true,
                                 default = newJString("DescribeIndexFields"))
  if valid_606519 != nil:
    section.add "Action", valid_606519
  var valid_606520 = query.getOrDefault("Version")
  valid_606520 = validateParameter(valid_606520, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_606520 != nil:
    section.add "Version", valid_606520
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606521 = header.getOrDefault("X-Amz-Signature")
  valid_606521 = validateParameter(valid_606521, JString, required = false,
                                 default = nil)
  if valid_606521 != nil:
    section.add "X-Amz-Signature", valid_606521
  var valid_606522 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606522 = validateParameter(valid_606522, JString, required = false,
                                 default = nil)
  if valid_606522 != nil:
    section.add "X-Amz-Content-Sha256", valid_606522
  var valid_606523 = header.getOrDefault("X-Amz-Date")
  valid_606523 = validateParameter(valid_606523, JString, required = false,
                                 default = nil)
  if valid_606523 != nil:
    section.add "X-Amz-Date", valid_606523
  var valid_606524 = header.getOrDefault("X-Amz-Credential")
  valid_606524 = validateParameter(valid_606524, JString, required = false,
                                 default = nil)
  if valid_606524 != nil:
    section.add "X-Amz-Credential", valid_606524
  var valid_606525 = header.getOrDefault("X-Amz-Security-Token")
  valid_606525 = validateParameter(valid_606525, JString, required = false,
                                 default = nil)
  if valid_606525 != nil:
    section.add "X-Amz-Security-Token", valid_606525
  var valid_606526 = header.getOrDefault("X-Amz-Algorithm")
  valid_606526 = validateParameter(valid_606526, JString, required = false,
                                 default = nil)
  if valid_606526 != nil:
    section.add "X-Amz-Algorithm", valid_606526
  var valid_606527 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606527 = validateParameter(valid_606527, JString, required = false,
                                 default = nil)
  if valid_606527 != nil:
    section.add "X-Amz-SignedHeaders", valid_606527
  result.add "header", section
  ## parameters in `formData` object:
  ##   FieldNames: JArray
  ##             : Limits the <code>DescribeIndexFields</code> response to the specified fields.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  var valid_606528 = formData.getOrDefault("FieldNames")
  valid_606528 = validateParameter(valid_606528, JArray, required = false,
                                 default = nil)
  if valid_606528 != nil:
    section.add "FieldNames", valid_606528
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_606529 = formData.getOrDefault("DomainName")
  valid_606529 = validateParameter(valid_606529, JString, required = true,
                                 default = nil)
  if valid_606529 != nil:
    section.add "DomainName", valid_606529
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606530: Call_PostDescribeIndexFields_606516; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. Shows all fields by default.
  ## 
  let valid = call_606530.validator(path, query, header, formData, body)
  let scheme = call_606530.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606530.url(scheme.get, call_606530.host, call_606530.base,
                         call_606530.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606530, url, valid)

proc call*(call_606531: Call_PostDescribeIndexFields_606516; DomainName: string;
          FieldNames: JsonNode = nil; Action: string = "DescribeIndexFields";
          Version: string = "2011-02-01"): Recallable =
  ## postDescribeIndexFields
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. Shows all fields by default.
  ##   FieldNames: JArray
  ##             : Limits the <code>DescribeIndexFields</code> response to the specified fields.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606532 = newJObject()
  var formData_606533 = newJObject()
  if FieldNames != nil:
    formData_606533.add "FieldNames", FieldNames
  add(formData_606533, "DomainName", newJString(DomainName))
  add(query_606532, "Action", newJString(Action))
  add(query_606532, "Version", newJString(Version))
  result = call_606531.call(nil, query_606532, nil, formData_606533, nil)

var postDescribeIndexFields* = Call_PostDescribeIndexFields_606516(
    name: "postDescribeIndexFields", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeIndexFields",
    validator: validate_PostDescribeIndexFields_606517, base: "/",
    url: url_PostDescribeIndexFields_606518, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeIndexFields_606499 = ref object of OpenApiRestCall_605589
proc url_GetDescribeIndexFields_606501(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeIndexFields_606500(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. Shows all fields by default.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   FieldNames: JArray
  ##             : Limits the <code>DescribeIndexFields</code> response to the specified fields.
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_606502 = query.getOrDefault("DomainName")
  valid_606502 = validateParameter(valid_606502, JString, required = true,
                                 default = nil)
  if valid_606502 != nil:
    section.add "DomainName", valid_606502
  var valid_606503 = query.getOrDefault("Action")
  valid_606503 = validateParameter(valid_606503, JString, required = true,
                                 default = newJString("DescribeIndexFields"))
  if valid_606503 != nil:
    section.add "Action", valid_606503
  var valid_606504 = query.getOrDefault("Version")
  valid_606504 = validateParameter(valid_606504, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_606504 != nil:
    section.add "Version", valid_606504
  var valid_606505 = query.getOrDefault("FieldNames")
  valid_606505 = validateParameter(valid_606505, JArray, required = false,
                                 default = nil)
  if valid_606505 != nil:
    section.add "FieldNames", valid_606505
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606506 = header.getOrDefault("X-Amz-Signature")
  valid_606506 = validateParameter(valid_606506, JString, required = false,
                                 default = nil)
  if valid_606506 != nil:
    section.add "X-Amz-Signature", valid_606506
  var valid_606507 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606507 = validateParameter(valid_606507, JString, required = false,
                                 default = nil)
  if valid_606507 != nil:
    section.add "X-Amz-Content-Sha256", valid_606507
  var valid_606508 = header.getOrDefault("X-Amz-Date")
  valid_606508 = validateParameter(valid_606508, JString, required = false,
                                 default = nil)
  if valid_606508 != nil:
    section.add "X-Amz-Date", valid_606508
  var valid_606509 = header.getOrDefault("X-Amz-Credential")
  valid_606509 = validateParameter(valid_606509, JString, required = false,
                                 default = nil)
  if valid_606509 != nil:
    section.add "X-Amz-Credential", valid_606509
  var valid_606510 = header.getOrDefault("X-Amz-Security-Token")
  valid_606510 = validateParameter(valid_606510, JString, required = false,
                                 default = nil)
  if valid_606510 != nil:
    section.add "X-Amz-Security-Token", valid_606510
  var valid_606511 = header.getOrDefault("X-Amz-Algorithm")
  valid_606511 = validateParameter(valid_606511, JString, required = false,
                                 default = nil)
  if valid_606511 != nil:
    section.add "X-Amz-Algorithm", valid_606511
  var valid_606512 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606512 = validateParameter(valid_606512, JString, required = false,
                                 default = nil)
  if valid_606512 != nil:
    section.add "X-Amz-SignedHeaders", valid_606512
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606513: Call_GetDescribeIndexFields_606499; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. Shows all fields by default.
  ## 
  let valid = call_606513.validator(path, query, header, formData, body)
  let scheme = call_606513.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606513.url(scheme.get, call_606513.host, call_606513.base,
                         call_606513.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606513, url, valid)

proc call*(call_606514: Call_GetDescribeIndexFields_606499; DomainName: string;
          Action: string = "DescribeIndexFields"; Version: string = "2011-02-01";
          FieldNames: JsonNode = nil): Recallable =
  ## getDescribeIndexFields
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. Shows all fields by default.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   FieldNames: JArray
  ##             : Limits the <code>DescribeIndexFields</code> response to the specified fields.
  var query_606515 = newJObject()
  add(query_606515, "DomainName", newJString(DomainName))
  add(query_606515, "Action", newJString(Action))
  add(query_606515, "Version", newJString(Version))
  if FieldNames != nil:
    query_606515.add "FieldNames", FieldNames
  result = call_606514.call(nil, query_606515, nil, nil, nil)

var getDescribeIndexFields* = Call_GetDescribeIndexFields_606499(
    name: "getDescribeIndexFields", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeIndexFields",
    validator: validate_GetDescribeIndexFields_606500, base: "/",
    url: url_GetDescribeIndexFields_606501, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeRankExpressions_606551 = ref object of OpenApiRestCall_605589
proc url_PostDescribeRankExpressions_606553(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeRankExpressions_606552(path: JsonNode; query: JsonNode;
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
  var valid_606554 = query.getOrDefault("Action")
  valid_606554 = validateParameter(valid_606554, JString, required = true, default = newJString(
      "DescribeRankExpressions"))
  if valid_606554 != nil:
    section.add "Action", valid_606554
  var valid_606555 = query.getOrDefault("Version")
  valid_606555 = validateParameter(valid_606555, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_606555 != nil:
    section.add "Version", valid_606555
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606556 = header.getOrDefault("X-Amz-Signature")
  valid_606556 = validateParameter(valid_606556, JString, required = false,
                                 default = nil)
  if valid_606556 != nil:
    section.add "X-Amz-Signature", valid_606556
  var valid_606557 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606557 = validateParameter(valid_606557, JString, required = false,
                                 default = nil)
  if valid_606557 != nil:
    section.add "X-Amz-Content-Sha256", valid_606557
  var valid_606558 = header.getOrDefault("X-Amz-Date")
  valid_606558 = validateParameter(valid_606558, JString, required = false,
                                 default = nil)
  if valid_606558 != nil:
    section.add "X-Amz-Date", valid_606558
  var valid_606559 = header.getOrDefault("X-Amz-Credential")
  valid_606559 = validateParameter(valid_606559, JString, required = false,
                                 default = nil)
  if valid_606559 != nil:
    section.add "X-Amz-Credential", valid_606559
  var valid_606560 = header.getOrDefault("X-Amz-Security-Token")
  valid_606560 = validateParameter(valid_606560, JString, required = false,
                                 default = nil)
  if valid_606560 != nil:
    section.add "X-Amz-Security-Token", valid_606560
  var valid_606561 = header.getOrDefault("X-Amz-Algorithm")
  valid_606561 = validateParameter(valid_606561, JString, required = false,
                                 default = nil)
  if valid_606561 != nil:
    section.add "X-Amz-Algorithm", valid_606561
  var valid_606562 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606562 = validateParameter(valid_606562, JString, required = false,
                                 default = nil)
  if valid_606562 != nil:
    section.add "X-Amz-SignedHeaders", valid_606562
  result.add "header", section
  ## parameters in `formData` object:
  ##   RankNames: JArray
  ##            : Limits the <code>DescribeRankExpressions</code> response to the specified fields.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  var valid_606563 = formData.getOrDefault("RankNames")
  valid_606563 = validateParameter(valid_606563, JArray, required = false,
                                 default = nil)
  if valid_606563 != nil:
    section.add "RankNames", valid_606563
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_606564 = formData.getOrDefault("DomainName")
  valid_606564 = validateParameter(valid_606564, JString, required = true,
                                 default = nil)
  if valid_606564 != nil:
    section.add "DomainName", valid_606564
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606565: Call_PostDescribeRankExpressions_606551; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the rank expressions configured for the search domain. Can be limited to specific rank expressions by name. Shows all rank expressions by default. 
  ## 
  let valid = call_606565.validator(path, query, header, formData, body)
  let scheme = call_606565.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606565.url(scheme.get, call_606565.host, call_606565.base,
                         call_606565.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606565, url, valid)

proc call*(call_606566: Call_PostDescribeRankExpressions_606551;
          DomainName: string; RankNames: JsonNode = nil;
          Action: string = "DescribeRankExpressions"; Version: string = "2011-02-01"): Recallable =
  ## postDescribeRankExpressions
  ## Gets the rank expressions configured for the search domain. Can be limited to specific rank expressions by name. Shows all rank expressions by default. 
  ##   RankNames: JArray
  ##            : Limits the <code>DescribeRankExpressions</code> response to the specified fields.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606567 = newJObject()
  var formData_606568 = newJObject()
  if RankNames != nil:
    formData_606568.add "RankNames", RankNames
  add(formData_606568, "DomainName", newJString(DomainName))
  add(query_606567, "Action", newJString(Action))
  add(query_606567, "Version", newJString(Version))
  result = call_606566.call(nil, query_606567, nil, formData_606568, nil)

var postDescribeRankExpressions* = Call_PostDescribeRankExpressions_606551(
    name: "postDescribeRankExpressions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeRankExpressions",
    validator: validate_PostDescribeRankExpressions_606552, base: "/",
    url: url_PostDescribeRankExpressions_606553,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeRankExpressions_606534 = ref object of OpenApiRestCall_605589
proc url_GetDescribeRankExpressions_606536(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeRankExpressions_606535(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the rank expressions configured for the search domain. Can be limited to specific rank expressions by name. Shows all rank expressions by default. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   RankNames: JArray
  ##            : Limits the <code>DescribeRankExpressions</code> response to the specified fields.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_606537 = query.getOrDefault("DomainName")
  valid_606537 = validateParameter(valid_606537, JString, required = true,
                                 default = nil)
  if valid_606537 != nil:
    section.add "DomainName", valid_606537
  var valid_606538 = query.getOrDefault("RankNames")
  valid_606538 = validateParameter(valid_606538, JArray, required = false,
                                 default = nil)
  if valid_606538 != nil:
    section.add "RankNames", valid_606538
  var valid_606539 = query.getOrDefault("Action")
  valid_606539 = validateParameter(valid_606539, JString, required = true, default = newJString(
      "DescribeRankExpressions"))
  if valid_606539 != nil:
    section.add "Action", valid_606539
  var valid_606540 = query.getOrDefault("Version")
  valid_606540 = validateParameter(valid_606540, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_606540 != nil:
    section.add "Version", valid_606540
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606541 = header.getOrDefault("X-Amz-Signature")
  valid_606541 = validateParameter(valid_606541, JString, required = false,
                                 default = nil)
  if valid_606541 != nil:
    section.add "X-Amz-Signature", valid_606541
  var valid_606542 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606542 = validateParameter(valid_606542, JString, required = false,
                                 default = nil)
  if valid_606542 != nil:
    section.add "X-Amz-Content-Sha256", valid_606542
  var valid_606543 = header.getOrDefault("X-Amz-Date")
  valid_606543 = validateParameter(valid_606543, JString, required = false,
                                 default = nil)
  if valid_606543 != nil:
    section.add "X-Amz-Date", valid_606543
  var valid_606544 = header.getOrDefault("X-Amz-Credential")
  valid_606544 = validateParameter(valid_606544, JString, required = false,
                                 default = nil)
  if valid_606544 != nil:
    section.add "X-Amz-Credential", valid_606544
  var valid_606545 = header.getOrDefault("X-Amz-Security-Token")
  valid_606545 = validateParameter(valid_606545, JString, required = false,
                                 default = nil)
  if valid_606545 != nil:
    section.add "X-Amz-Security-Token", valid_606545
  var valid_606546 = header.getOrDefault("X-Amz-Algorithm")
  valid_606546 = validateParameter(valid_606546, JString, required = false,
                                 default = nil)
  if valid_606546 != nil:
    section.add "X-Amz-Algorithm", valid_606546
  var valid_606547 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606547 = validateParameter(valid_606547, JString, required = false,
                                 default = nil)
  if valid_606547 != nil:
    section.add "X-Amz-SignedHeaders", valid_606547
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606548: Call_GetDescribeRankExpressions_606534; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the rank expressions configured for the search domain. Can be limited to specific rank expressions by name. Shows all rank expressions by default. 
  ## 
  let valid = call_606548.validator(path, query, header, formData, body)
  let scheme = call_606548.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606548.url(scheme.get, call_606548.host, call_606548.base,
                         call_606548.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606548, url, valid)

proc call*(call_606549: Call_GetDescribeRankExpressions_606534; DomainName: string;
          RankNames: JsonNode = nil; Action: string = "DescribeRankExpressions";
          Version: string = "2011-02-01"): Recallable =
  ## getDescribeRankExpressions
  ## Gets the rank expressions configured for the search domain. Can be limited to specific rank expressions by name. Shows all rank expressions by default. 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   RankNames: JArray
  ##            : Limits the <code>DescribeRankExpressions</code> response to the specified fields.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606550 = newJObject()
  add(query_606550, "DomainName", newJString(DomainName))
  if RankNames != nil:
    query_606550.add "RankNames", RankNames
  add(query_606550, "Action", newJString(Action))
  add(query_606550, "Version", newJString(Version))
  result = call_606549.call(nil, query_606550, nil, nil, nil)

var getDescribeRankExpressions* = Call_GetDescribeRankExpressions_606534(
    name: "getDescribeRankExpressions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeRankExpressions",
    validator: validate_GetDescribeRankExpressions_606535, base: "/",
    url: url_GetDescribeRankExpressions_606536,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeServiceAccessPolicies_606585 = ref object of OpenApiRestCall_605589
proc url_PostDescribeServiceAccessPolicies_606587(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeServiceAccessPolicies_606586(path: JsonNode;
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
  var valid_606588 = query.getOrDefault("Action")
  valid_606588 = validateParameter(valid_606588, JString, required = true, default = newJString(
      "DescribeServiceAccessPolicies"))
  if valid_606588 != nil:
    section.add "Action", valid_606588
  var valid_606589 = query.getOrDefault("Version")
  valid_606589 = validateParameter(valid_606589, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_606589 != nil:
    section.add "Version", valid_606589
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606590 = header.getOrDefault("X-Amz-Signature")
  valid_606590 = validateParameter(valid_606590, JString, required = false,
                                 default = nil)
  if valid_606590 != nil:
    section.add "X-Amz-Signature", valid_606590
  var valid_606591 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606591 = validateParameter(valid_606591, JString, required = false,
                                 default = nil)
  if valid_606591 != nil:
    section.add "X-Amz-Content-Sha256", valid_606591
  var valid_606592 = header.getOrDefault("X-Amz-Date")
  valid_606592 = validateParameter(valid_606592, JString, required = false,
                                 default = nil)
  if valid_606592 != nil:
    section.add "X-Amz-Date", valid_606592
  var valid_606593 = header.getOrDefault("X-Amz-Credential")
  valid_606593 = validateParameter(valid_606593, JString, required = false,
                                 default = nil)
  if valid_606593 != nil:
    section.add "X-Amz-Credential", valid_606593
  var valid_606594 = header.getOrDefault("X-Amz-Security-Token")
  valid_606594 = validateParameter(valid_606594, JString, required = false,
                                 default = nil)
  if valid_606594 != nil:
    section.add "X-Amz-Security-Token", valid_606594
  var valid_606595 = header.getOrDefault("X-Amz-Algorithm")
  valid_606595 = validateParameter(valid_606595, JString, required = false,
                                 default = nil)
  if valid_606595 != nil:
    section.add "X-Amz-Algorithm", valid_606595
  var valid_606596 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606596 = validateParameter(valid_606596, JString, required = false,
                                 default = nil)
  if valid_606596 != nil:
    section.add "X-Amz-SignedHeaders", valid_606596
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_606597 = formData.getOrDefault("DomainName")
  valid_606597 = validateParameter(valid_606597, JString, required = true,
                                 default = nil)
  if valid_606597 != nil:
    section.add "DomainName", valid_606597
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606598: Call_PostDescribeServiceAccessPolicies_606585;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets information about the resource-based policies that control access to the domain's document and search services.
  ## 
  let valid = call_606598.validator(path, query, header, formData, body)
  let scheme = call_606598.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606598.url(scheme.get, call_606598.host, call_606598.base,
                         call_606598.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606598, url, valid)

proc call*(call_606599: Call_PostDescribeServiceAccessPolicies_606585;
          DomainName: string; Action: string = "DescribeServiceAccessPolicies";
          Version: string = "2011-02-01"): Recallable =
  ## postDescribeServiceAccessPolicies
  ## Gets information about the resource-based policies that control access to the domain's document and search services.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606600 = newJObject()
  var formData_606601 = newJObject()
  add(formData_606601, "DomainName", newJString(DomainName))
  add(query_606600, "Action", newJString(Action))
  add(query_606600, "Version", newJString(Version))
  result = call_606599.call(nil, query_606600, nil, formData_606601, nil)

var postDescribeServiceAccessPolicies* = Call_PostDescribeServiceAccessPolicies_606585(
    name: "postDescribeServiceAccessPolicies", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeServiceAccessPolicies",
    validator: validate_PostDescribeServiceAccessPolicies_606586, base: "/",
    url: url_PostDescribeServiceAccessPolicies_606587,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeServiceAccessPolicies_606569 = ref object of OpenApiRestCall_605589
proc url_GetDescribeServiceAccessPolicies_606571(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeServiceAccessPolicies_606570(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about the resource-based policies that control access to the domain's document and search services.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_606572 = query.getOrDefault("DomainName")
  valid_606572 = validateParameter(valid_606572, JString, required = true,
                                 default = nil)
  if valid_606572 != nil:
    section.add "DomainName", valid_606572
  var valid_606573 = query.getOrDefault("Action")
  valid_606573 = validateParameter(valid_606573, JString, required = true, default = newJString(
      "DescribeServiceAccessPolicies"))
  if valid_606573 != nil:
    section.add "Action", valid_606573
  var valid_606574 = query.getOrDefault("Version")
  valid_606574 = validateParameter(valid_606574, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_606574 != nil:
    section.add "Version", valid_606574
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606575 = header.getOrDefault("X-Amz-Signature")
  valid_606575 = validateParameter(valid_606575, JString, required = false,
                                 default = nil)
  if valid_606575 != nil:
    section.add "X-Amz-Signature", valid_606575
  var valid_606576 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606576 = validateParameter(valid_606576, JString, required = false,
                                 default = nil)
  if valid_606576 != nil:
    section.add "X-Amz-Content-Sha256", valid_606576
  var valid_606577 = header.getOrDefault("X-Amz-Date")
  valid_606577 = validateParameter(valid_606577, JString, required = false,
                                 default = nil)
  if valid_606577 != nil:
    section.add "X-Amz-Date", valid_606577
  var valid_606578 = header.getOrDefault("X-Amz-Credential")
  valid_606578 = validateParameter(valid_606578, JString, required = false,
                                 default = nil)
  if valid_606578 != nil:
    section.add "X-Amz-Credential", valid_606578
  var valid_606579 = header.getOrDefault("X-Amz-Security-Token")
  valid_606579 = validateParameter(valid_606579, JString, required = false,
                                 default = nil)
  if valid_606579 != nil:
    section.add "X-Amz-Security-Token", valid_606579
  var valid_606580 = header.getOrDefault("X-Amz-Algorithm")
  valid_606580 = validateParameter(valid_606580, JString, required = false,
                                 default = nil)
  if valid_606580 != nil:
    section.add "X-Amz-Algorithm", valid_606580
  var valid_606581 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606581 = validateParameter(valid_606581, JString, required = false,
                                 default = nil)
  if valid_606581 != nil:
    section.add "X-Amz-SignedHeaders", valid_606581
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606582: Call_GetDescribeServiceAccessPolicies_606569;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Gets information about the resource-based policies that control access to the domain's document and search services.
  ## 
  let valid = call_606582.validator(path, query, header, formData, body)
  let scheme = call_606582.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606582.url(scheme.get, call_606582.host, call_606582.base,
                         call_606582.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606582, url, valid)

proc call*(call_606583: Call_GetDescribeServiceAccessPolicies_606569;
          DomainName: string; Action: string = "DescribeServiceAccessPolicies";
          Version: string = "2011-02-01"): Recallable =
  ## getDescribeServiceAccessPolicies
  ## Gets information about the resource-based policies that control access to the domain's document and search services.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606584 = newJObject()
  add(query_606584, "DomainName", newJString(DomainName))
  add(query_606584, "Action", newJString(Action))
  add(query_606584, "Version", newJString(Version))
  result = call_606583.call(nil, query_606584, nil, nil, nil)

var getDescribeServiceAccessPolicies* = Call_GetDescribeServiceAccessPolicies_606569(
    name: "getDescribeServiceAccessPolicies", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeServiceAccessPolicies",
    validator: validate_GetDescribeServiceAccessPolicies_606570, base: "/",
    url: url_GetDescribeServiceAccessPolicies_606571,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeStemmingOptions_606618 = ref object of OpenApiRestCall_605589
proc url_PostDescribeStemmingOptions_606620(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeStemmingOptions_606619(path: JsonNode; query: JsonNode;
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
  var valid_606621 = query.getOrDefault("Action")
  valid_606621 = validateParameter(valid_606621, JString, required = true, default = newJString(
      "DescribeStemmingOptions"))
  if valid_606621 != nil:
    section.add "Action", valid_606621
  var valid_606622 = query.getOrDefault("Version")
  valid_606622 = validateParameter(valid_606622, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_606622 != nil:
    section.add "Version", valid_606622
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606623 = header.getOrDefault("X-Amz-Signature")
  valid_606623 = validateParameter(valid_606623, JString, required = false,
                                 default = nil)
  if valid_606623 != nil:
    section.add "X-Amz-Signature", valid_606623
  var valid_606624 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606624 = validateParameter(valid_606624, JString, required = false,
                                 default = nil)
  if valid_606624 != nil:
    section.add "X-Amz-Content-Sha256", valid_606624
  var valid_606625 = header.getOrDefault("X-Amz-Date")
  valid_606625 = validateParameter(valid_606625, JString, required = false,
                                 default = nil)
  if valid_606625 != nil:
    section.add "X-Amz-Date", valid_606625
  var valid_606626 = header.getOrDefault("X-Amz-Credential")
  valid_606626 = validateParameter(valid_606626, JString, required = false,
                                 default = nil)
  if valid_606626 != nil:
    section.add "X-Amz-Credential", valid_606626
  var valid_606627 = header.getOrDefault("X-Amz-Security-Token")
  valid_606627 = validateParameter(valid_606627, JString, required = false,
                                 default = nil)
  if valid_606627 != nil:
    section.add "X-Amz-Security-Token", valid_606627
  var valid_606628 = header.getOrDefault("X-Amz-Algorithm")
  valid_606628 = validateParameter(valid_606628, JString, required = false,
                                 default = nil)
  if valid_606628 != nil:
    section.add "X-Amz-Algorithm", valid_606628
  var valid_606629 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606629 = validateParameter(valid_606629, JString, required = false,
                                 default = nil)
  if valid_606629 != nil:
    section.add "X-Amz-SignedHeaders", valid_606629
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_606630 = formData.getOrDefault("DomainName")
  valid_606630 = validateParameter(valid_606630, JString, required = true,
                                 default = nil)
  if valid_606630 != nil:
    section.add "DomainName", valid_606630
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606631: Call_PostDescribeStemmingOptions_606618; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the stemming dictionary configured for the search domain.
  ## 
  let valid = call_606631.validator(path, query, header, formData, body)
  let scheme = call_606631.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606631.url(scheme.get, call_606631.host, call_606631.base,
                         call_606631.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606631, url, valid)

proc call*(call_606632: Call_PostDescribeStemmingOptions_606618;
          DomainName: string; Action: string = "DescribeStemmingOptions";
          Version: string = "2011-02-01"): Recallable =
  ## postDescribeStemmingOptions
  ## Gets the stemming dictionary configured for the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606633 = newJObject()
  var formData_606634 = newJObject()
  add(formData_606634, "DomainName", newJString(DomainName))
  add(query_606633, "Action", newJString(Action))
  add(query_606633, "Version", newJString(Version))
  result = call_606632.call(nil, query_606633, nil, formData_606634, nil)

var postDescribeStemmingOptions* = Call_PostDescribeStemmingOptions_606618(
    name: "postDescribeStemmingOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeStemmingOptions",
    validator: validate_PostDescribeStemmingOptions_606619, base: "/",
    url: url_PostDescribeStemmingOptions_606620,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeStemmingOptions_606602 = ref object of OpenApiRestCall_605589
proc url_GetDescribeStemmingOptions_606604(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeStemmingOptions_606603(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the stemming dictionary configured for the search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_606605 = query.getOrDefault("DomainName")
  valid_606605 = validateParameter(valid_606605, JString, required = true,
                                 default = nil)
  if valid_606605 != nil:
    section.add "DomainName", valid_606605
  var valid_606606 = query.getOrDefault("Action")
  valid_606606 = validateParameter(valid_606606, JString, required = true, default = newJString(
      "DescribeStemmingOptions"))
  if valid_606606 != nil:
    section.add "Action", valid_606606
  var valid_606607 = query.getOrDefault("Version")
  valid_606607 = validateParameter(valid_606607, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_606607 != nil:
    section.add "Version", valid_606607
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606608 = header.getOrDefault("X-Amz-Signature")
  valid_606608 = validateParameter(valid_606608, JString, required = false,
                                 default = nil)
  if valid_606608 != nil:
    section.add "X-Amz-Signature", valid_606608
  var valid_606609 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606609 = validateParameter(valid_606609, JString, required = false,
                                 default = nil)
  if valid_606609 != nil:
    section.add "X-Amz-Content-Sha256", valid_606609
  var valid_606610 = header.getOrDefault("X-Amz-Date")
  valid_606610 = validateParameter(valid_606610, JString, required = false,
                                 default = nil)
  if valid_606610 != nil:
    section.add "X-Amz-Date", valid_606610
  var valid_606611 = header.getOrDefault("X-Amz-Credential")
  valid_606611 = validateParameter(valid_606611, JString, required = false,
                                 default = nil)
  if valid_606611 != nil:
    section.add "X-Amz-Credential", valid_606611
  var valid_606612 = header.getOrDefault("X-Amz-Security-Token")
  valid_606612 = validateParameter(valid_606612, JString, required = false,
                                 default = nil)
  if valid_606612 != nil:
    section.add "X-Amz-Security-Token", valid_606612
  var valid_606613 = header.getOrDefault("X-Amz-Algorithm")
  valid_606613 = validateParameter(valid_606613, JString, required = false,
                                 default = nil)
  if valid_606613 != nil:
    section.add "X-Amz-Algorithm", valid_606613
  var valid_606614 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606614 = validateParameter(valid_606614, JString, required = false,
                                 default = nil)
  if valid_606614 != nil:
    section.add "X-Amz-SignedHeaders", valid_606614
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606615: Call_GetDescribeStemmingOptions_606602; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the stemming dictionary configured for the search domain.
  ## 
  let valid = call_606615.validator(path, query, header, formData, body)
  let scheme = call_606615.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606615.url(scheme.get, call_606615.host, call_606615.base,
                         call_606615.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606615, url, valid)

proc call*(call_606616: Call_GetDescribeStemmingOptions_606602; DomainName: string;
          Action: string = "DescribeStemmingOptions"; Version: string = "2011-02-01"): Recallable =
  ## getDescribeStemmingOptions
  ## Gets the stemming dictionary configured for the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606617 = newJObject()
  add(query_606617, "DomainName", newJString(DomainName))
  add(query_606617, "Action", newJString(Action))
  add(query_606617, "Version", newJString(Version))
  result = call_606616.call(nil, query_606617, nil, nil, nil)

var getDescribeStemmingOptions* = Call_GetDescribeStemmingOptions_606602(
    name: "getDescribeStemmingOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeStemmingOptions",
    validator: validate_GetDescribeStemmingOptions_606603, base: "/",
    url: url_GetDescribeStemmingOptions_606604,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeStopwordOptions_606651 = ref object of OpenApiRestCall_605589
proc url_PostDescribeStopwordOptions_606653(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeStopwordOptions_606652(path: JsonNode; query: JsonNode;
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
  var valid_606654 = query.getOrDefault("Action")
  valid_606654 = validateParameter(valid_606654, JString, required = true, default = newJString(
      "DescribeStopwordOptions"))
  if valid_606654 != nil:
    section.add "Action", valid_606654
  var valid_606655 = query.getOrDefault("Version")
  valid_606655 = validateParameter(valid_606655, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_606655 != nil:
    section.add "Version", valid_606655
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606656 = header.getOrDefault("X-Amz-Signature")
  valid_606656 = validateParameter(valid_606656, JString, required = false,
                                 default = nil)
  if valid_606656 != nil:
    section.add "X-Amz-Signature", valid_606656
  var valid_606657 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606657 = validateParameter(valid_606657, JString, required = false,
                                 default = nil)
  if valid_606657 != nil:
    section.add "X-Amz-Content-Sha256", valid_606657
  var valid_606658 = header.getOrDefault("X-Amz-Date")
  valid_606658 = validateParameter(valid_606658, JString, required = false,
                                 default = nil)
  if valid_606658 != nil:
    section.add "X-Amz-Date", valid_606658
  var valid_606659 = header.getOrDefault("X-Amz-Credential")
  valid_606659 = validateParameter(valid_606659, JString, required = false,
                                 default = nil)
  if valid_606659 != nil:
    section.add "X-Amz-Credential", valid_606659
  var valid_606660 = header.getOrDefault("X-Amz-Security-Token")
  valid_606660 = validateParameter(valid_606660, JString, required = false,
                                 default = nil)
  if valid_606660 != nil:
    section.add "X-Amz-Security-Token", valid_606660
  var valid_606661 = header.getOrDefault("X-Amz-Algorithm")
  valid_606661 = validateParameter(valid_606661, JString, required = false,
                                 default = nil)
  if valid_606661 != nil:
    section.add "X-Amz-Algorithm", valid_606661
  var valid_606662 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606662 = validateParameter(valid_606662, JString, required = false,
                                 default = nil)
  if valid_606662 != nil:
    section.add "X-Amz-SignedHeaders", valid_606662
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_606663 = formData.getOrDefault("DomainName")
  valid_606663 = validateParameter(valid_606663, JString, required = true,
                                 default = nil)
  if valid_606663 != nil:
    section.add "DomainName", valid_606663
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606664: Call_PostDescribeStopwordOptions_606651; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the stopwords configured for the search domain.
  ## 
  let valid = call_606664.validator(path, query, header, formData, body)
  let scheme = call_606664.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606664.url(scheme.get, call_606664.host, call_606664.base,
                         call_606664.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606664, url, valid)

proc call*(call_606665: Call_PostDescribeStopwordOptions_606651;
          DomainName: string; Action: string = "DescribeStopwordOptions";
          Version: string = "2011-02-01"): Recallable =
  ## postDescribeStopwordOptions
  ## Gets the stopwords configured for the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606666 = newJObject()
  var formData_606667 = newJObject()
  add(formData_606667, "DomainName", newJString(DomainName))
  add(query_606666, "Action", newJString(Action))
  add(query_606666, "Version", newJString(Version))
  result = call_606665.call(nil, query_606666, nil, formData_606667, nil)

var postDescribeStopwordOptions* = Call_PostDescribeStopwordOptions_606651(
    name: "postDescribeStopwordOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeStopwordOptions",
    validator: validate_PostDescribeStopwordOptions_606652, base: "/",
    url: url_PostDescribeStopwordOptions_606653,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeStopwordOptions_606635 = ref object of OpenApiRestCall_605589
proc url_GetDescribeStopwordOptions_606637(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeStopwordOptions_606636(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the stopwords configured for the search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_606638 = query.getOrDefault("DomainName")
  valid_606638 = validateParameter(valid_606638, JString, required = true,
                                 default = nil)
  if valid_606638 != nil:
    section.add "DomainName", valid_606638
  var valid_606639 = query.getOrDefault("Action")
  valid_606639 = validateParameter(valid_606639, JString, required = true, default = newJString(
      "DescribeStopwordOptions"))
  if valid_606639 != nil:
    section.add "Action", valid_606639
  var valid_606640 = query.getOrDefault("Version")
  valid_606640 = validateParameter(valid_606640, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_606640 != nil:
    section.add "Version", valid_606640
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606641 = header.getOrDefault("X-Amz-Signature")
  valid_606641 = validateParameter(valid_606641, JString, required = false,
                                 default = nil)
  if valid_606641 != nil:
    section.add "X-Amz-Signature", valid_606641
  var valid_606642 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606642 = validateParameter(valid_606642, JString, required = false,
                                 default = nil)
  if valid_606642 != nil:
    section.add "X-Amz-Content-Sha256", valid_606642
  var valid_606643 = header.getOrDefault("X-Amz-Date")
  valid_606643 = validateParameter(valid_606643, JString, required = false,
                                 default = nil)
  if valid_606643 != nil:
    section.add "X-Amz-Date", valid_606643
  var valid_606644 = header.getOrDefault("X-Amz-Credential")
  valid_606644 = validateParameter(valid_606644, JString, required = false,
                                 default = nil)
  if valid_606644 != nil:
    section.add "X-Amz-Credential", valid_606644
  var valid_606645 = header.getOrDefault("X-Amz-Security-Token")
  valid_606645 = validateParameter(valid_606645, JString, required = false,
                                 default = nil)
  if valid_606645 != nil:
    section.add "X-Amz-Security-Token", valid_606645
  var valid_606646 = header.getOrDefault("X-Amz-Algorithm")
  valid_606646 = validateParameter(valid_606646, JString, required = false,
                                 default = nil)
  if valid_606646 != nil:
    section.add "X-Amz-Algorithm", valid_606646
  var valid_606647 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606647 = validateParameter(valid_606647, JString, required = false,
                                 default = nil)
  if valid_606647 != nil:
    section.add "X-Amz-SignedHeaders", valid_606647
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606648: Call_GetDescribeStopwordOptions_606635; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the stopwords configured for the search domain.
  ## 
  let valid = call_606648.validator(path, query, header, formData, body)
  let scheme = call_606648.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606648.url(scheme.get, call_606648.host, call_606648.base,
                         call_606648.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606648, url, valid)

proc call*(call_606649: Call_GetDescribeStopwordOptions_606635; DomainName: string;
          Action: string = "DescribeStopwordOptions"; Version: string = "2011-02-01"): Recallable =
  ## getDescribeStopwordOptions
  ## Gets the stopwords configured for the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606650 = newJObject()
  add(query_606650, "DomainName", newJString(DomainName))
  add(query_606650, "Action", newJString(Action))
  add(query_606650, "Version", newJString(Version))
  result = call_606649.call(nil, query_606650, nil, nil, nil)

var getDescribeStopwordOptions* = Call_GetDescribeStopwordOptions_606635(
    name: "getDescribeStopwordOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeStopwordOptions",
    validator: validate_GetDescribeStopwordOptions_606636, base: "/",
    url: url_GetDescribeStopwordOptions_606637,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeSynonymOptions_606684 = ref object of OpenApiRestCall_605589
proc url_PostDescribeSynonymOptions_606686(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeSynonymOptions_606685(path: JsonNode; query: JsonNode;
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
  var valid_606687 = query.getOrDefault("Action")
  valid_606687 = validateParameter(valid_606687, JString, required = true,
                                 default = newJString("DescribeSynonymOptions"))
  if valid_606687 != nil:
    section.add "Action", valid_606687
  var valid_606688 = query.getOrDefault("Version")
  valid_606688 = validateParameter(valid_606688, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_606688 != nil:
    section.add "Version", valid_606688
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606689 = header.getOrDefault("X-Amz-Signature")
  valid_606689 = validateParameter(valid_606689, JString, required = false,
                                 default = nil)
  if valid_606689 != nil:
    section.add "X-Amz-Signature", valid_606689
  var valid_606690 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606690 = validateParameter(valid_606690, JString, required = false,
                                 default = nil)
  if valid_606690 != nil:
    section.add "X-Amz-Content-Sha256", valid_606690
  var valid_606691 = header.getOrDefault("X-Amz-Date")
  valid_606691 = validateParameter(valid_606691, JString, required = false,
                                 default = nil)
  if valid_606691 != nil:
    section.add "X-Amz-Date", valid_606691
  var valid_606692 = header.getOrDefault("X-Amz-Credential")
  valid_606692 = validateParameter(valid_606692, JString, required = false,
                                 default = nil)
  if valid_606692 != nil:
    section.add "X-Amz-Credential", valid_606692
  var valid_606693 = header.getOrDefault("X-Amz-Security-Token")
  valid_606693 = validateParameter(valid_606693, JString, required = false,
                                 default = nil)
  if valid_606693 != nil:
    section.add "X-Amz-Security-Token", valid_606693
  var valid_606694 = header.getOrDefault("X-Amz-Algorithm")
  valid_606694 = validateParameter(valid_606694, JString, required = false,
                                 default = nil)
  if valid_606694 != nil:
    section.add "X-Amz-Algorithm", valid_606694
  var valid_606695 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606695 = validateParameter(valid_606695, JString, required = false,
                                 default = nil)
  if valid_606695 != nil:
    section.add "X-Amz-SignedHeaders", valid_606695
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_606696 = formData.getOrDefault("DomainName")
  valid_606696 = validateParameter(valid_606696, JString, required = true,
                                 default = nil)
  if valid_606696 != nil:
    section.add "DomainName", valid_606696
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606697: Call_PostDescribeSynonymOptions_606684; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the synonym dictionary configured for the search domain.
  ## 
  let valid = call_606697.validator(path, query, header, formData, body)
  let scheme = call_606697.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606697.url(scheme.get, call_606697.host, call_606697.base,
                         call_606697.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606697, url, valid)

proc call*(call_606698: Call_PostDescribeSynonymOptions_606684; DomainName: string;
          Action: string = "DescribeSynonymOptions"; Version: string = "2011-02-01"): Recallable =
  ## postDescribeSynonymOptions
  ## Gets the synonym dictionary configured for the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606699 = newJObject()
  var formData_606700 = newJObject()
  add(formData_606700, "DomainName", newJString(DomainName))
  add(query_606699, "Action", newJString(Action))
  add(query_606699, "Version", newJString(Version))
  result = call_606698.call(nil, query_606699, nil, formData_606700, nil)

var postDescribeSynonymOptions* = Call_PostDescribeSynonymOptions_606684(
    name: "postDescribeSynonymOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeSynonymOptions",
    validator: validate_PostDescribeSynonymOptions_606685, base: "/",
    url: url_PostDescribeSynonymOptions_606686,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeSynonymOptions_606668 = ref object of OpenApiRestCall_605589
proc url_GetDescribeSynonymOptions_606670(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeSynonymOptions_606669(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets the synonym dictionary configured for the search domain.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_606671 = query.getOrDefault("DomainName")
  valid_606671 = validateParameter(valid_606671, JString, required = true,
                                 default = nil)
  if valid_606671 != nil:
    section.add "DomainName", valid_606671
  var valid_606672 = query.getOrDefault("Action")
  valid_606672 = validateParameter(valid_606672, JString, required = true,
                                 default = newJString("DescribeSynonymOptions"))
  if valid_606672 != nil:
    section.add "Action", valid_606672
  var valid_606673 = query.getOrDefault("Version")
  valid_606673 = validateParameter(valid_606673, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_606673 != nil:
    section.add "Version", valid_606673
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606674 = header.getOrDefault("X-Amz-Signature")
  valid_606674 = validateParameter(valid_606674, JString, required = false,
                                 default = nil)
  if valid_606674 != nil:
    section.add "X-Amz-Signature", valid_606674
  var valid_606675 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606675 = validateParameter(valid_606675, JString, required = false,
                                 default = nil)
  if valid_606675 != nil:
    section.add "X-Amz-Content-Sha256", valid_606675
  var valid_606676 = header.getOrDefault("X-Amz-Date")
  valid_606676 = validateParameter(valid_606676, JString, required = false,
                                 default = nil)
  if valid_606676 != nil:
    section.add "X-Amz-Date", valid_606676
  var valid_606677 = header.getOrDefault("X-Amz-Credential")
  valid_606677 = validateParameter(valid_606677, JString, required = false,
                                 default = nil)
  if valid_606677 != nil:
    section.add "X-Amz-Credential", valid_606677
  var valid_606678 = header.getOrDefault("X-Amz-Security-Token")
  valid_606678 = validateParameter(valid_606678, JString, required = false,
                                 default = nil)
  if valid_606678 != nil:
    section.add "X-Amz-Security-Token", valid_606678
  var valid_606679 = header.getOrDefault("X-Amz-Algorithm")
  valid_606679 = validateParameter(valid_606679, JString, required = false,
                                 default = nil)
  if valid_606679 != nil:
    section.add "X-Amz-Algorithm", valid_606679
  var valid_606680 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606680 = validateParameter(valid_606680, JString, required = false,
                                 default = nil)
  if valid_606680 != nil:
    section.add "X-Amz-SignedHeaders", valid_606680
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606681: Call_GetDescribeSynonymOptions_606668; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets the synonym dictionary configured for the search domain.
  ## 
  let valid = call_606681.validator(path, query, header, formData, body)
  let scheme = call_606681.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606681.url(scheme.get, call_606681.host, call_606681.base,
                         call_606681.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606681, url, valid)

proc call*(call_606682: Call_GetDescribeSynonymOptions_606668; DomainName: string;
          Action: string = "DescribeSynonymOptions"; Version: string = "2011-02-01"): Recallable =
  ## getDescribeSynonymOptions
  ## Gets the synonym dictionary configured for the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606683 = newJObject()
  add(query_606683, "DomainName", newJString(DomainName))
  add(query_606683, "Action", newJString(Action))
  add(query_606683, "Version", newJString(Version))
  result = call_606682.call(nil, query_606683, nil, nil, nil)

var getDescribeSynonymOptions* = Call_GetDescribeSynonymOptions_606668(
    name: "getDescribeSynonymOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeSynonymOptions",
    validator: validate_GetDescribeSynonymOptions_606669, base: "/",
    url: url_GetDescribeSynonymOptions_606670,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostIndexDocuments_606717 = ref object of OpenApiRestCall_605589
proc url_PostIndexDocuments_606719(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostIndexDocuments_606718(path: JsonNode; query: JsonNode;
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
  var valid_606720 = query.getOrDefault("Action")
  valid_606720 = validateParameter(valid_606720, JString, required = true,
                                 default = newJString("IndexDocuments"))
  if valid_606720 != nil:
    section.add "Action", valid_606720
  var valid_606721 = query.getOrDefault("Version")
  valid_606721 = validateParameter(valid_606721, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_606721 != nil:
    section.add "Version", valid_606721
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606722 = header.getOrDefault("X-Amz-Signature")
  valid_606722 = validateParameter(valid_606722, JString, required = false,
                                 default = nil)
  if valid_606722 != nil:
    section.add "X-Amz-Signature", valid_606722
  var valid_606723 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606723 = validateParameter(valid_606723, JString, required = false,
                                 default = nil)
  if valid_606723 != nil:
    section.add "X-Amz-Content-Sha256", valid_606723
  var valid_606724 = header.getOrDefault("X-Amz-Date")
  valid_606724 = validateParameter(valid_606724, JString, required = false,
                                 default = nil)
  if valid_606724 != nil:
    section.add "X-Amz-Date", valid_606724
  var valid_606725 = header.getOrDefault("X-Amz-Credential")
  valid_606725 = validateParameter(valid_606725, JString, required = false,
                                 default = nil)
  if valid_606725 != nil:
    section.add "X-Amz-Credential", valid_606725
  var valid_606726 = header.getOrDefault("X-Amz-Security-Token")
  valid_606726 = validateParameter(valid_606726, JString, required = false,
                                 default = nil)
  if valid_606726 != nil:
    section.add "X-Amz-Security-Token", valid_606726
  var valid_606727 = header.getOrDefault("X-Amz-Algorithm")
  valid_606727 = validateParameter(valid_606727, JString, required = false,
                                 default = nil)
  if valid_606727 != nil:
    section.add "X-Amz-Algorithm", valid_606727
  var valid_606728 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606728 = validateParameter(valid_606728, JString, required = false,
                                 default = nil)
  if valid_606728 != nil:
    section.add "X-Amz-SignedHeaders", valid_606728
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_606729 = formData.getOrDefault("DomainName")
  valid_606729 = validateParameter(valid_606729, JString, required = true,
                                 default = nil)
  if valid_606729 != nil:
    section.add "DomainName", valid_606729
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606730: Call_PostIndexDocuments_606717; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Tells the search domain to start indexing its documents using the latest text processing options and <code>IndexFields</code>. This operation must be invoked to make options whose <a>OptionStatus</a> has <code>OptionState</code> of <code>RequiresIndexDocuments</code> visible in search results.
  ## 
  let valid = call_606730.validator(path, query, header, formData, body)
  let scheme = call_606730.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606730.url(scheme.get, call_606730.host, call_606730.base,
                         call_606730.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606730, url, valid)

proc call*(call_606731: Call_PostIndexDocuments_606717; DomainName: string;
          Action: string = "IndexDocuments"; Version: string = "2011-02-01"): Recallable =
  ## postIndexDocuments
  ## Tells the search domain to start indexing its documents using the latest text processing options and <code>IndexFields</code>. This operation must be invoked to make options whose <a>OptionStatus</a> has <code>OptionState</code> of <code>RequiresIndexDocuments</code> visible in search results.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606732 = newJObject()
  var formData_606733 = newJObject()
  add(formData_606733, "DomainName", newJString(DomainName))
  add(query_606732, "Action", newJString(Action))
  add(query_606732, "Version", newJString(Version))
  result = call_606731.call(nil, query_606732, nil, formData_606733, nil)

var postIndexDocuments* = Call_PostIndexDocuments_606717(
    name: "postIndexDocuments", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=IndexDocuments",
    validator: validate_PostIndexDocuments_606718, base: "/",
    url: url_PostIndexDocuments_606719, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIndexDocuments_606701 = ref object of OpenApiRestCall_605589
proc url_GetIndexDocuments_606703(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetIndexDocuments_606702(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
  ## Tells the search domain to start indexing its documents using the latest text processing options and <code>IndexFields</code>. This operation must be invoked to make options whose <a>OptionStatus</a> has <code>OptionState</code> of <code>RequiresIndexDocuments</code> visible in search results.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_606704 = query.getOrDefault("DomainName")
  valid_606704 = validateParameter(valid_606704, JString, required = true,
                                 default = nil)
  if valid_606704 != nil:
    section.add "DomainName", valid_606704
  var valid_606705 = query.getOrDefault("Action")
  valid_606705 = validateParameter(valid_606705, JString, required = true,
                                 default = newJString("IndexDocuments"))
  if valid_606705 != nil:
    section.add "Action", valid_606705
  var valid_606706 = query.getOrDefault("Version")
  valid_606706 = validateParameter(valid_606706, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_606706 != nil:
    section.add "Version", valid_606706
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606707 = header.getOrDefault("X-Amz-Signature")
  valid_606707 = validateParameter(valid_606707, JString, required = false,
                                 default = nil)
  if valid_606707 != nil:
    section.add "X-Amz-Signature", valid_606707
  var valid_606708 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606708 = validateParameter(valid_606708, JString, required = false,
                                 default = nil)
  if valid_606708 != nil:
    section.add "X-Amz-Content-Sha256", valid_606708
  var valid_606709 = header.getOrDefault("X-Amz-Date")
  valid_606709 = validateParameter(valid_606709, JString, required = false,
                                 default = nil)
  if valid_606709 != nil:
    section.add "X-Amz-Date", valid_606709
  var valid_606710 = header.getOrDefault("X-Amz-Credential")
  valid_606710 = validateParameter(valid_606710, JString, required = false,
                                 default = nil)
  if valid_606710 != nil:
    section.add "X-Amz-Credential", valid_606710
  var valid_606711 = header.getOrDefault("X-Amz-Security-Token")
  valid_606711 = validateParameter(valid_606711, JString, required = false,
                                 default = nil)
  if valid_606711 != nil:
    section.add "X-Amz-Security-Token", valid_606711
  var valid_606712 = header.getOrDefault("X-Amz-Algorithm")
  valid_606712 = validateParameter(valid_606712, JString, required = false,
                                 default = nil)
  if valid_606712 != nil:
    section.add "X-Amz-Algorithm", valid_606712
  var valid_606713 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606713 = validateParameter(valid_606713, JString, required = false,
                                 default = nil)
  if valid_606713 != nil:
    section.add "X-Amz-SignedHeaders", valid_606713
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606714: Call_GetIndexDocuments_606701; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Tells the search domain to start indexing its documents using the latest text processing options and <code>IndexFields</code>. This operation must be invoked to make options whose <a>OptionStatus</a> has <code>OptionState</code> of <code>RequiresIndexDocuments</code> visible in search results.
  ## 
  let valid = call_606714.validator(path, query, header, formData, body)
  let scheme = call_606714.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606714.url(scheme.get, call_606714.host, call_606714.base,
                         call_606714.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606714, url, valid)

proc call*(call_606715: Call_GetIndexDocuments_606701; DomainName: string;
          Action: string = "IndexDocuments"; Version: string = "2011-02-01"): Recallable =
  ## getIndexDocuments
  ## Tells the search domain to start indexing its documents using the latest text processing options and <code>IndexFields</code>. This operation must be invoked to make options whose <a>OptionStatus</a> has <code>OptionState</code> of <code>RequiresIndexDocuments</code> visible in search results.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606716 = newJObject()
  add(query_606716, "DomainName", newJString(DomainName))
  add(query_606716, "Action", newJString(Action))
  add(query_606716, "Version", newJString(Version))
  result = call_606715.call(nil, query_606716, nil, nil, nil)

var getIndexDocuments* = Call_GetIndexDocuments_606701(name: "getIndexDocuments",
    meth: HttpMethod.HttpGet, host: "cloudsearch.amazonaws.com",
    route: "/#Action=IndexDocuments", validator: validate_GetIndexDocuments_606702,
    base: "/", url: url_GetIndexDocuments_606703,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateAvailabilityOptions_606751 = ref object of OpenApiRestCall_605589
proc url_PostUpdateAvailabilityOptions_606753(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostUpdateAvailabilityOptions_606752(path: JsonNode; query: JsonNode;
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
  var valid_606754 = query.getOrDefault("Action")
  valid_606754 = validateParameter(valid_606754, JString, required = true, default = newJString(
      "UpdateAvailabilityOptions"))
  if valid_606754 != nil:
    section.add "Action", valid_606754
  var valid_606755 = query.getOrDefault("Version")
  valid_606755 = validateParameter(valid_606755, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_606755 != nil:
    section.add "Version", valid_606755
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606756 = header.getOrDefault("X-Amz-Signature")
  valid_606756 = validateParameter(valid_606756, JString, required = false,
                                 default = nil)
  if valid_606756 != nil:
    section.add "X-Amz-Signature", valid_606756
  var valid_606757 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606757 = validateParameter(valid_606757, JString, required = false,
                                 default = nil)
  if valid_606757 != nil:
    section.add "X-Amz-Content-Sha256", valid_606757
  var valid_606758 = header.getOrDefault("X-Amz-Date")
  valid_606758 = validateParameter(valid_606758, JString, required = false,
                                 default = nil)
  if valid_606758 != nil:
    section.add "X-Amz-Date", valid_606758
  var valid_606759 = header.getOrDefault("X-Amz-Credential")
  valid_606759 = validateParameter(valid_606759, JString, required = false,
                                 default = nil)
  if valid_606759 != nil:
    section.add "X-Amz-Credential", valid_606759
  var valid_606760 = header.getOrDefault("X-Amz-Security-Token")
  valid_606760 = validateParameter(valid_606760, JString, required = false,
                                 default = nil)
  if valid_606760 != nil:
    section.add "X-Amz-Security-Token", valid_606760
  var valid_606761 = header.getOrDefault("X-Amz-Algorithm")
  valid_606761 = validateParameter(valid_606761, JString, required = false,
                                 default = nil)
  if valid_606761 != nil:
    section.add "X-Amz-Algorithm", valid_606761
  var valid_606762 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606762 = validateParameter(valid_606762, JString, required = false,
                                 default = nil)
  if valid_606762 != nil:
    section.add "X-Amz-SignedHeaders", valid_606762
  result.add "header", section
  ## parameters in `formData` object:
  ##   MultiAZ: JBool (required)
  ##          : You expand an existing search domain to a second Availability Zone by setting the Multi-AZ option to true. Similarly, you can turn off the Multi-AZ option to downgrade the domain to a single Availability Zone by setting the Multi-AZ option to <code>false</code>. 
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `MultiAZ` field"
  var valid_606763 = formData.getOrDefault("MultiAZ")
  valid_606763 = validateParameter(valid_606763, JBool, required = true, default = nil)
  if valid_606763 != nil:
    section.add "MultiAZ", valid_606763
  var valid_606764 = formData.getOrDefault("DomainName")
  valid_606764 = validateParameter(valid_606764, JString, required = true,
                                 default = nil)
  if valid_606764 != nil:
    section.add "DomainName", valid_606764
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606765: Call_PostUpdateAvailabilityOptions_606751; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_606765.validator(path, query, header, formData, body)
  let scheme = call_606765.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606765.url(scheme.get, call_606765.host, call_606765.base,
                         call_606765.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606765, url, valid)

proc call*(call_606766: Call_PostUpdateAvailabilityOptions_606751; MultiAZ: bool;
          DomainName: string; Action: string = "UpdateAvailabilityOptions";
          Version: string = "2011-02-01"): Recallable =
  ## postUpdateAvailabilityOptions
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   MultiAZ: bool (required)
  ##          : You expand an existing search domain to a second Availability Zone by setting the Multi-AZ option to true. Similarly, you can turn off the Multi-AZ option to downgrade the domain to a single Availability Zone by setting the Multi-AZ option to <code>false</code>. 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606767 = newJObject()
  var formData_606768 = newJObject()
  add(formData_606768, "MultiAZ", newJBool(MultiAZ))
  add(formData_606768, "DomainName", newJString(DomainName))
  add(query_606767, "Action", newJString(Action))
  add(query_606767, "Version", newJString(Version))
  result = call_606766.call(nil, query_606767, nil, formData_606768, nil)

var postUpdateAvailabilityOptions* = Call_PostUpdateAvailabilityOptions_606751(
    name: "postUpdateAvailabilityOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateAvailabilityOptions",
    validator: validate_PostUpdateAvailabilityOptions_606752, base: "/",
    url: url_PostUpdateAvailabilityOptions_606753,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateAvailabilityOptions_606734 = ref object of OpenApiRestCall_605589
proc url_GetUpdateAvailabilityOptions_606736(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUpdateAvailabilityOptions_606735(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   MultiAZ: JBool (required)
  ##          : You expand an existing search domain to a second Availability Zone by setting the Multi-AZ option to true. Similarly, you can turn off the Multi-AZ option to downgrade the domain to a single Availability Zone by setting the Multi-AZ option to <code>false</code>. 
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_606737 = query.getOrDefault("DomainName")
  valid_606737 = validateParameter(valid_606737, JString, required = true,
                                 default = nil)
  if valid_606737 != nil:
    section.add "DomainName", valid_606737
  var valid_606738 = query.getOrDefault("Action")
  valid_606738 = validateParameter(valid_606738, JString, required = true, default = newJString(
      "UpdateAvailabilityOptions"))
  if valid_606738 != nil:
    section.add "Action", valid_606738
  var valid_606739 = query.getOrDefault("MultiAZ")
  valid_606739 = validateParameter(valid_606739, JBool, required = true, default = nil)
  if valid_606739 != nil:
    section.add "MultiAZ", valid_606739
  var valid_606740 = query.getOrDefault("Version")
  valid_606740 = validateParameter(valid_606740, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_606740 != nil:
    section.add "Version", valid_606740
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606741 = header.getOrDefault("X-Amz-Signature")
  valid_606741 = validateParameter(valid_606741, JString, required = false,
                                 default = nil)
  if valid_606741 != nil:
    section.add "X-Amz-Signature", valid_606741
  var valid_606742 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606742 = validateParameter(valid_606742, JString, required = false,
                                 default = nil)
  if valid_606742 != nil:
    section.add "X-Amz-Content-Sha256", valid_606742
  var valid_606743 = header.getOrDefault("X-Amz-Date")
  valid_606743 = validateParameter(valid_606743, JString, required = false,
                                 default = nil)
  if valid_606743 != nil:
    section.add "X-Amz-Date", valid_606743
  var valid_606744 = header.getOrDefault("X-Amz-Credential")
  valid_606744 = validateParameter(valid_606744, JString, required = false,
                                 default = nil)
  if valid_606744 != nil:
    section.add "X-Amz-Credential", valid_606744
  var valid_606745 = header.getOrDefault("X-Amz-Security-Token")
  valid_606745 = validateParameter(valid_606745, JString, required = false,
                                 default = nil)
  if valid_606745 != nil:
    section.add "X-Amz-Security-Token", valid_606745
  var valid_606746 = header.getOrDefault("X-Amz-Algorithm")
  valid_606746 = validateParameter(valid_606746, JString, required = false,
                                 default = nil)
  if valid_606746 != nil:
    section.add "X-Amz-Algorithm", valid_606746
  var valid_606747 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606747 = validateParameter(valid_606747, JString, required = false,
                                 default = nil)
  if valid_606747 != nil:
    section.add "X-Amz-SignedHeaders", valid_606747
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606748: Call_GetUpdateAvailabilityOptions_606734; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_606748.validator(path, query, header, formData, body)
  let scheme = call_606748.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606748.url(scheme.get, call_606748.host, call_606748.base,
                         call_606748.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606748, url, valid)

proc call*(call_606749: Call_GetUpdateAvailabilityOptions_606734;
          DomainName: string; MultiAZ: bool;
          Action: string = "UpdateAvailabilityOptions";
          Version: string = "2011-02-01"): Recallable =
  ## getUpdateAvailabilityOptions
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   MultiAZ: bool (required)
  ##          : You expand an existing search domain to a second Availability Zone by setting the Multi-AZ option to true. Similarly, you can turn off the Multi-AZ option to downgrade the domain to a single Availability Zone by setting the Multi-AZ option to <code>false</code>. 
  ##   Version: string (required)
  var query_606750 = newJObject()
  add(query_606750, "DomainName", newJString(DomainName))
  add(query_606750, "Action", newJString(Action))
  add(query_606750, "MultiAZ", newJBool(MultiAZ))
  add(query_606750, "Version", newJString(Version))
  result = call_606749.call(nil, query_606750, nil, nil, nil)

var getUpdateAvailabilityOptions* = Call_GetUpdateAvailabilityOptions_606734(
    name: "getUpdateAvailabilityOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateAvailabilityOptions",
    validator: validate_GetUpdateAvailabilityOptions_606735, base: "/",
    url: url_GetUpdateAvailabilityOptions_606736,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateDefaultSearchField_606786 = ref object of OpenApiRestCall_605589
proc url_PostUpdateDefaultSearchField_606788(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostUpdateDefaultSearchField_606787(path: JsonNode; query: JsonNode;
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
  var valid_606789 = query.getOrDefault("Action")
  valid_606789 = validateParameter(valid_606789, JString, required = true, default = newJString(
      "UpdateDefaultSearchField"))
  if valid_606789 != nil:
    section.add "Action", valid_606789
  var valid_606790 = query.getOrDefault("Version")
  valid_606790 = validateParameter(valid_606790, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_606790 != nil:
    section.add "Version", valid_606790
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606791 = header.getOrDefault("X-Amz-Signature")
  valid_606791 = validateParameter(valid_606791, JString, required = false,
                                 default = nil)
  if valid_606791 != nil:
    section.add "X-Amz-Signature", valid_606791
  var valid_606792 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606792 = validateParameter(valid_606792, JString, required = false,
                                 default = nil)
  if valid_606792 != nil:
    section.add "X-Amz-Content-Sha256", valid_606792
  var valid_606793 = header.getOrDefault("X-Amz-Date")
  valid_606793 = validateParameter(valid_606793, JString, required = false,
                                 default = nil)
  if valid_606793 != nil:
    section.add "X-Amz-Date", valid_606793
  var valid_606794 = header.getOrDefault("X-Amz-Credential")
  valid_606794 = validateParameter(valid_606794, JString, required = false,
                                 default = nil)
  if valid_606794 != nil:
    section.add "X-Amz-Credential", valid_606794
  var valid_606795 = header.getOrDefault("X-Amz-Security-Token")
  valid_606795 = validateParameter(valid_606795, JString, required = false,
                                 default = nil)
  if valid_606795 != nil:
    section.add "X-Amz-Security-Token", valid_606795
  var valid_606796 = header.getOrDefault("X-Amz-Algorithm")
  valid_606796 = validateParameter(valid_606796, JString, required = false,
                                 default = nil)
  if valid_606796 != nil:
    section.add "X-Amz-Algorithm", valid_606796
  var valid_606797 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606797 = validateParameter(valid_606797, JString, required = false,
                                 default = nil)
  if valid_606797 != nil:
    section.add "X-Amz-SignedHeaders", valid_606797
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   DefaultSearchField: JString (required)
  ##                     : The text field to search if the search request does not specify which field to search. The default search field is used when search terms are specified with the <code>q</code> parameter, or if a match expression specified with the <code>bq</code> parameter does not constrain the search to a particular field. The default is an empty string, which automatically searches all text fields.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_606798 = formData.getOrDefault("DomainName")
  valid_606798 = validateParameter(valid_606798, JString, required = true,
                                 default = nil)
  if valid_606798 != nil:
    section.add "DomainName", valid_606798
  var valid_606799 = formData.getOrDefault("DefaultSearchField")
  valid_606799 = validateParameter(valid_606799, JString, required = true,
                                 default = nil)
  if valid_606799 != nil:
    section.add "DefaultSearchField", valid_606799
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606800: Call_PostUpdateDefaultSearchField_606786; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the default search field for the search domain. The default search field is the text field that is searched when a search request does not specify which fields to search. By default, it is configured to include the contents of all of the domain's text fields. 
  ## 
  let valid = call_606800.validator(path, query, header, formData, body)
  let scheme = call_606800.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606800.url(scheme.get, call_606800.host, call_606800.base,
                         call_606800.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606800, url, valid)

proc call*(call_606801: Call_PostUpdateDefaultSearchField_606786;
          DomainName: string; DefaultSearchField: string;
          Action: string = "UpdateDefaultSearchField";
          Version: string = "2011-02-01"): Recallable =
  ## postUpdateDefaultSearchField
  ## Configures the default search field for the search domain. The default search field is the text field that is searched when a search request does not specify which fields to search. By default, it is configured to include the contents of all of the domain's text fields. 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   DefaultSearchField: string (required)
  ##                     : The text field to search if the search request does not specify which field to search. The default search field is used when search terms are specified with the <code>q</code> parameter, or if a match expression specified with the <code>bq</code> parameter does not constrain the search to a particular field. The default is an empty string, which automatically searches all text fields.
  ##   Version: string (required)
  var query_606802 = newJObject()
  var formData_606803 = newJObject()
  add(formData_606803, "DomainName", newJString(DomainName))
  add(query_606802, "Action", newJString(Action))
  add(formData_606803, "DefaultSearchField", newJString(DefaultSearchField))
  add(query_606802, "Version", newJString(Version))
  result = call_606801.call(nil, query_606802, nil, formData_606803, nil)

var postUpdateDefaultSearchField* = Call_PostUpdateDefaultSearchField_606786(
    name: "postUpdateDefaultSearchField", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateDefaultSearchField",
    validator: validate_PostUpdateDefaultSearchField_606787, base: "/",
    url: url_PostUpdateDefaultSearchField_606788,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateDefaultSearchField_606769 = ref object of OpenApiRestCall_605589
proc url_GetUpdateDefaultSearchField_606771(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUpdateDefaultSearchField_606770(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures the default search field for the search domain. The default search field is the text field that is searched when a search request does not specify which fields to search. By default, it is configured to include the contents of all of the domain's text fields. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   DefaultSearchField: JString (required)
  ##                     : The text field to search if the search request does not specify which field to search. The default search field is used when search terms are specified with the <code>q</code> parameter, or if a match expression specified with the <code>bq</code> parameter does not constrain the search to a particular field. The default is an empty string, which automatically searches all text fields.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_606772 = query.getOrDefault("DomainName")
  valid_606772 = validateParameter(valid_606772, JString, required = true,
                                 default = nil)
  if valid_606772 != nil:
    section.add "DomainName", valid_606772
  var valid_606773 = query.getOrDefault("DefaultSearchField")
  valid_606773 = validateParameter(valid_606773, JString, required = true,
                                 default = nil)
  if valid_606773 != nil:
    section.add "DefaultSearchField", valid_606773
  var valid_606774 = query.getOrDefault("Action")
  valid_606774 = validateParameter(valid_606774, JString, required = true, default = newJString(
      "UpdateDefaultSearchField"))
  if valid_606774 != nil:
    section.add "Action", valid_606774
  var valid_606775 = query.getOrDefault("Version")
  valid_606775 = validateParameter(valid_606775, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_606775 != nil:
    section.add "Version", valid_606775
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606776 = header.getOrDefault("X-Amz-Signature")
  valid_606776 = validateParameter(valid_606776, JString, required = false,
                                 default = nil)
  if valid_606776 != nil:
    section.add "X-Amz-Signature", valid_606776
  var valid_606777 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606777 = validateParameter(valid_606777, JString, required = false,
                                 default = nil)
  if valid_606777 != nil:
    section.add "X-Amz-Content-Sha256", valid_606777
  var valid_606778 = header.getOrDefault("X-Amz-Date")
  valid_606778 = validateParameter(valid_606778, JString, required = false,
                                 default = nil)
  if valid_606778 != nil:
    section.add "X-Amz-Date", valid_606778
  var valid_606779 = header.getOrDefault("X-Amz-Credential")
  valid_606779 = validateParameter(valid_606779, JString, required = false,
                                 default = nil)
  if valid_606779 != nil:
    section.add "X-Amz-Credential", valid_606779
  var valid_606780 = header.getOrDefault("X-Amz-Security-Token")
  valid_606780 = validateParameter(valid_606780, JString, required = false,
                                 default = nil)
  if valid_606780 != nil:
    section.add "X-Amz-Security-Token", valid_606780
  var valid_606781 = header.getOrDefault("X-Amz-Algorithm")
  valid_606781 = validateParameter(valid_606781, JString, required = false,
                                 default = nil)
  if valid_606781 != nil:
    section.add "X-Amz-Algorithm", valid_606781
  var valid_606782 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606782 = validateParameter(valid_606782, JString, required = false,
                                 default = nil)
  if valid_606782 != nil:
    section.add "X-Amz-SignedHeaders", valid_606782
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606783: Call_GetUpdateDefaultSearchField_606769; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the default search field for the search domain. The default search field is the text field that is searched when a search request does not specify which fields to search. By default, it is configured to include the contents of all of the domain's text fields. 
  ## 
  let valid = call_606783.validator(path, query, header, formData, body)
  let scheme = call_606783.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606783.url(scheme.get, call_606783.host, call_606783.base,
                         call_606783.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606783, url, valid)

proc call*(call_606784: Call_GetUpdateDefaultSearchField_606769;
          DomainName: string; DefaultSearchField: string;
          Action: string = "UpdateDefaultSearchField";
          Version: string = "2011-02-01"): Recallable =
  ## getUpdateDefaultSearchField
  ## Configures the default search field for the search domain. The default search field is the text field that is searched when a search request does not specify which fields to search. By default, it is configured to include the contents of all of the domain's text fields. 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   DefaultSearchField: string (required)
  ##                     : The text field to search if the search request does not specify which field to search. The default search field is used when search terms are specified with the <code>q</code> parameter, or if a match expression specified with the <code>bq</code> parameter does not constrain the search to a particular field. The default is an empty string, which automatically searches all text fields.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606785 = newJObject()
  add(query_606785, "DomainName", newJString(DomainName))
  add(query_606785, "DefaultSearchField", newJString(DefaultSearchField))
  add(query_606785, "Action", newJString(Action))
  add(query_606785, "Version", newJString(Version))
  result = call_606784.call(nil, query_606785, nil, nil, nil)

var getUpdateDefaultSearchField* = Call_GetUpdateDefaultSearchField_606769(
    name: "getUpdateDefaultSearchField", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateDefaultSearchField",
    validator: validate_GetUpdateDefaultSearchField_606770, base: "/",
    url: url_GetUpdateDefaultSearchField_606771,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateServiceAccessPolicies_606821 = ref object of OpenApiRestCall_605589
proc url_PostUpdateServiceAccessPolicies_606823(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostUpdateServiceAccessPolicies_606822(path: JsonNode;
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
  var valid_606824 = query.getOrDefault("Action")
  valid_606824 = validateParameter(valid_606824, JString, required = true, default = newJString(
      "UpdateServiceAccessPolicies"))
  if valid_606824 != nil:
    section.add "Action", valid_606824
  var valid_606825 = query.getOrDefault("Version")
  valid_606825 = validateParameter(valid_606825, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_606825 != nil:
    section.add "Version", valid_606825
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606826 = header.getOrDefault("X-Amz-Signature")
  valid_606826 = validateParameter(valid_606826, JString, required = false,
                                 default = nil)
  if valid_606826 != nil:
    section.add "X-Amz-Signature", valid_606826
  var valid_606827 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606827 = validateParameter(valid_606827, JString, required = false,
                                 default = nil)
  if valid_606827 != nil:
    section.add "X-Amz-Content-Sha256", valid_606827
  var valid_606828 = header.getOrDefault("X-Amz-Date")
  valid_606828 = validateParameter(valid_606828, JString, required = false,
                                 default = nil)
  if valid_606828 != nil:
    section.add "X-Amz-Date", valid_606828
  var valid_606829 = header.getOrDefault("X-Amz-Credential")
  valid_606829 = validateParameter(valid_606829, JString, required = false,
                                 default = nil)
  if valid_606829 != nil:
    section.add "X-Amz-Credential", valid_606829
  var valid_606830 = header.getOrDefault("X-Amz-Security-Token")
  valid_606830 = validateParameter(valid_606830, JString, required = false,
                                 default = nil)
  if valid_606830 != nil:
    section.add "X-Amz-Security-Token", valid_606830
  var valid_606831 = header.getOrDefault("X-Amz-Algorithm")
  valid_606831 = validateParameter(valid_606831, JString, required = false,
                                 default = nil)
  if valid_606831 != nil:
    section.add "X-Amz-Algorithm", valid_606831
  var valid_606832 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606832 = validateParameter(valid_606832, JString, required = false,
                                 default = nil)
  if valid_606832 != nil:
    section.add "X-Amz-SignedHeaders", valid_606832
  result.add "header", section
  ## parameters in `formData` object:
  ##   AccessPolicies: JString (required)
  ##                 : <p>An IAM access policy as described in <a 
  ## href="http://docs.aws.amazon.com/IAM/latest/UserGuide/index.html?AccessPolicyLanguage.html" target="_blank">The Access Policy Language</a> in <i>Using AWS Identity and Access Management</i>. The maximum size of an access policy document is 100 KB.</p> <p>Example: <code>{"Statement": [{"Effect":"Allow", "Action": "*", "Resource": "arn:aws:cs:us-east-1:1234567890:search/movies", "Condition": { "IpAddress": { "aws:SourceIp": ["203.0.113.1/32"] } }}, {"Effect":"Allow", "Action": "*", "Resource": "arn:aws:cs:us-east-1:1234567890:documents/movies", "Condition": { "IpAddress": { "aws:SourceIp": ["203.0.113.1/32"] } }} ] }</code></p>
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `AccessPolicies` field"
  var valid_606833 = formData.getOrDefault("AccessPolicies")
  valid_606833 = validateParameter(valid_606833, JString, required = true,
                                 default = nil)
  if valid_606833 != nil:
    section.add "AccessPolicies", valid_606833
  var valid_606834 = formData.getOrDefault("DomainName")
  valid_606834 = validateParameter(valid_606834, JString, required = true,
                                 default = nil)
  if valid_606834 != nil:
    section.add "DomainName", valid_606834
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606835: Call_PostUpdateServiceAccessPolicies_606821;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Configures the policies that control access to the domain's document and search services. The maximum size of an access policy document is 100 KB.
  ## 
  let valid = call_606835.validator(path, query, header, formData, body)
  let scheme = call_606835.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606835.url(scheme.get, call_606835.host, call_606835.base,
                         call_606835.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606835, url, valid)

proc call*(call_606836: Call_PostUpdateServiceAccessPolicies_606821;
          AccessPolicies: string; DomainName: string;
          Action: string = "UpdateServiceAccessPolicies";
          Version: string = "2011-02-01"): Recallable =
  ## postUpdateServiceAccessPolicies
  ## Configures the policies that control access to the domain's document and search services. The maximum size of an access policy document is 100 KB.
  ##   AccessPolicies: string (required)
  ##                 : <p>An IAM access policy as described in <a 
  ## href="http://docs.aws.amazon.com/IAM/latest/UserGuide/index.html?AccessPolicyLanguage.html" target="_blank">The Access Policy Language</a> in <i>Using AWS Identity and Access Management</i>. The maximum size of an access policy document is 100 KB.</p> <p>Example: <code>{"Statement": [{"Effect":"Allow", "Action": "*", "Resource": "arn:aws:cs:us-east-1:1234567890:search/movies", "Condition": { "IpAddress": { "aws:SourceIp": ["203.0.113.1/32"] } }}, {"Effect":"Allow", "Action": "*", "Resource": "arn:aws:cs:us-east-1:1234567890:documents/movies", "Condition": { "IpAddress": { "aws:SourceIp": ["203.0.113.1/32"] } }} ] }</code></p>
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606837 = newJObject()
  var formData_606838 = newJObject()
  add(formData_606838, "AccessPolicies", newJString(AccessPolicies))
  add(formData_606838, "DomainName", newJString(DomainName))
  add(query_606837, "Action", newJString(Action))
  add(query_606837, "Version", newJString(Version))
  result = call_606836.call(nil, query_606837, nil, formData_606838, nil)

var postUpdateServiceAccessPolicies* = Call_PostUpdateServiceAccessPolicies_606821(
    name: "postUpdateServiceAccessPolicies", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateServiceAccessPolicies",
    validator: validate_PostUpdateServiceAccessPolicies_606822, base: "/",
    url: url_PostUpdateServiceAccessPolicies_606823,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateServiceAccessPolicies_606804 = ref object of OpenApiRestCall_605589
proc url_GetUpdateServiceAccessPolicies_606806(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUpdateServiceAccessPolicies_606805(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures the policies that control access to the domain's document and search services. The maximum size of an access policy document is 100 KB.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   Version: JString (required)
  ##   AccessPolicies: JString (required)
  ##                 : <p>An IAM access policy as described in <a 
  ## href="http://docs.aws.amazon.com/IAM/latest/UserGuide/index.html?AccessPolicyLanguage.html" target="_blank">The Access Policy Language</a> in <i>Using AWS Identity and Access Management</i>. The maximum size of an access policy document is 100 KB.</p> <p>Example: <code>{"Statement": [{"Effect":"Allow", "Action": "*", "Resource": "arn:aws:cs:us-east-1:1234567890:search/movies", "Condition": { "IpAddress": { "aws:SourceIp": ["203.0.113.1/32"] } }}, {"Effect":"Allow", "Action": "*", "Resource": "arn:aws:cs:us-east-1:1234567890:documents/movies", "Condition": { "IpAddress": { "aws:SourceIp": ["203.0.113.1/32"] } }} ] }</code></p>
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `DomainName` field"
  var valid_606807 = query.getOrDefault("DomainName")
  valid_606807 = validateParameter(valid_606807, JString, required = true,
                                 default = nil)
  if valid_606807 != nil:
    section.add "DomainName", valid_606807
  var valid_606808 = query.getOrDefault("Action")
  valid_606808 = validateParameter(valid_606808, JString, required = true, default = newJString(
      "UpdateServiceAccessPolicies"))
  if valid_606808 != nil:
    section.add "Action", valid_606808
  var valid_606809 = query.getOrDefault("Version")
  valid_606809 = validateParameter(valid_606809, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_606809 != nil:
    section.add "Version", valid_606809
  var valid_606810 = query.getOrDefault("AccessPolicies")
  valid_606810 = validateParameter(valid_606810, JString, required = true,
                                 default = nil)
  if valid_606810 != nil:
    section.add "AccessPolicies", valid_606810
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606811 = header.getOrDefault("X-Amz-Signature")
  valid_606811 = validateParameter(valid_606811, JString, required = false,
                                 default = nil)
  if valid_606811 != nil:
    section.add "X-Amz-Signature", valid_606811
  var valid_606812 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606812 = validateParameter(valid_606812, JString, required = false,
                                 default = nil)
  if valid_606812 != nil:
    section.add "X-Amz-Content-Sha256", valid_606812
  var valid_606813 = header.getOrDefault("X-Amz-Date")
  valid_606813 = validateParameter(valid_606813, JString, required = false,
                                 default = nil)
  if valid_606813 != nil:
    section.add "X-Amz-Date", valid_606813
  var valid_606814 = header.getOrDefault("X-Amz-Credential")
  valid_606814 = validateParameter(valid_606814, JString, required = false,
                                 default = nil)
  if valid_606814 != nil:
    section.add "X-Amz-Credential", valid_606814
  var valid_606815 = header.getOrDefault("X-Amz-Security-Token")
  valid_606815 = validateParameter(valid_606815, JString, required = false,
                                 default = nil)
  if valid_606815 != nil:
    section.add "X-Amz-Security-Token", valid_606815
  var valid_606816 = header.getOrDefault("X-Amz-Algorithm")
  valid_606816 = validateParameter(valid_606816, JString, required = false,
                                 default = nil)
  if valid_606816 != nil:
    section.add "X-Amz-Algorithm", valid_606816
  var valid_606817 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606817 = validateParameter(valid_606817, JString, required = false,
                                 default = nil)
  if valid_606817 != nil:
    section.add "X-Amz-SignedHeaders", valid_606817
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606818: Call_GetUpdateServiceAccessPolicies_606804; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures the policies that control access to the domain's document and search services. The maximum size of an access policy document is 100 KB.
  ## 
  let valid = call_606818.validator(path, query, header, formData, body)
  let scheme = call_606818.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606818.url(scheme.get, call_606818.host, call_606818.base,
                         call_606818.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606818, url, valid)

proc call*(call_606819: Call_GetUpdateServiceAccessPolicies_606804;
          DomainName: string; AccessPolicies: string;
          Action: string = "UpdateServiceAccessPolicies";
          Version: string = "2011-02-01"): Recallable =
  ## getUpdateServiceAccessPolicies
  ## Configures the policies that control access to the domain's document and search services. The maximum size of an access policy document is 100 KB.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  ##   AccessPolicies: string (required)
  ##                 : <p>An IAM access policy as described in <a 
  ## href="http://docs.aws.amazon.com/IAM/latest/UserGuide/index.html?AccessPolicyLanguage.html" target="_blank">The Access Policy Language</a> in <i>Using AWS Identity and Access Management</i>. The maximum size of an access policy document is 100 KB.</p> <p>Example: <code>{"Statement": [{"Effect":"Allow", "Action": "*", "Resource": "arn:aws:cs:us-east-1:1234567890:search/movies", "Condition": { "IpAddress": { "aws:SourceIp": ["203.0.113.1/32"] } }}, {"Effect":"Allow", "Action": "*", "Resource": "arn:aws:cs:us-east-1:1234567890:documents/movies", "Condition": { "IpAddress": { "aws:SourceIp": ["203.0.113.1/32"] } }} ] }</code></p>
  var query_606820 = newJObject()
  add(query_606820, "DomainName", newJString(DomainName))
  add(query_606820, "Action", newJString(Action))
  add(query_606820, "Version", newJString(Version))
  add(query_606820, "AccessPolicies", newJString(AccessPolicies))
  result = call_606819.call(nil, query_606820, nil, nil, nil)

var getUpdateServiceAccessPolicies* = Call_GetUpdateServiceAccessPolicies_606804(
    name: "getUpdateServiceAccessPolicies", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateServiceAccessPolicies",
    validator: validate_GetUpdateServiceAccessPolicies_606805, base: "/",
    url: url_GetUpdateServiceAccessPolicies_606806,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateStemmingOptions_606856 = ref object of OpenApiRestCall_605589
proc url_PostUpdateStemmingOptions_606858(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostUpdateStemmingOptions_606857(path: JsonNode; query: JsonNode;
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
  var valid_606859 = query.getOrDefault("Action")
  valid_606859 = validateParameter(valid_606859, JString, required = true,
                                 default = newJString("UpdateStemmingOptions"))
  if valid_606859 != nil:
    section.add "Action", valid_606859
  var valid_606860 = query.getOrDefault("Version")
  valid_606860 = validateParameter(valid_606860, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_606860 != nil:
    section.add "Version", valid_606860
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606861 = header.getOrDefault("X-Amz-Signature")
  valid_606861 = validateParameter(valid_606861, JString, required = false,
                                 default = nil)
  if valid_606861 != nil:
    section.add "X-Amz-Signature", valid_606861
  var valid_606862 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606862 = validateParameter(valid_606862, JString, required = false,
                                 default = nil)
  if valid_606862 != nil:
    section.add "X-Amz-Content-Sha256", valid_606862
  var valid_606863 = header.getOrDefault("X-Amz-Date")
  valid_606863 = validateParameter(valid_606863, JString, required = false,
                                 default = nil)
  if valid_606863 != nil:
    section.add "X-Amz-Date", valid_606863
  var valid_606864 = header.getOrDefault("X-Amz-Credential")
  valid_606864 = validateParameter(valid_606864, JString, required = false,
                                 default = nil)
  if valid_606864 != nil:
    section.add "X-Amz-Credential", valid_606864
  var valid_606865 = header.getOrDefault("X-Amz-Security-Token")
  valid_606865 = validateParameter(valid_606865, JString, required = false,
                                 default = nil)
  if valid_606865 != nil:
    section.add "X-Amz-Security-Token", valid_606865
  var valid_606866 = header.getOrDefault("X-Amz-Algorithm")
  valid_606866 = validateParameter(valid_606866, JString, required = false,
                                 default = nil)
  if valid_606866 != nil:
    section.add "X-Amz-Algorithm", valid_606866
  var valid_606867 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606867 = validateParameter(valid_606867, JString, required = false,
                                 default = nil)
  if valid_606867 != nil:
    section.add "X-Amz-SignedHeaders", valid_606867
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Stems: JString (required)
  ##        : Maps terms to their stems, serialized as a JSON document. The document has a single object with one property "stems" whose value is an object mapping terms to their stems. The maximum size of a stemming document is 500 KB. Example: <code>{ "stems": {"people": "person", "walking": "walk"} }</code>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_606868 = formData.getOrDefault("DomainName")
  valid_606868 = validateParameter(valid_606868, JString, required = true,
                                 default = nil)
  if valid_606868 != nil:
    section.add "DomainName", valid_606868
  var valid_606869 = formData.getOrDefault("Stems")
  valid_606869 = validateParameter(valid_606869, JString, required = true,
                                 default = nil)
  if valid_606869 != nil:
    section.add "Stems", valid_606869
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606870: Call_PostUpdateStemmingOptions_606856; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a stemming dictionary for the search domain. The stemming dictionary is used during indexing and when processing search requests. The maximum size of the stemming dictionary is 500 KB.
  ## 
  let valid = call_606870.validator(path, query, header, formData, body)
  let scheme = call_606870.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606870.url(scheme.get, call_606870.host, call_606870.base,
                         call_606870.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606870, url, valid)

proc call*(call_606871: Call_PostUpdateStemmingOptions_606856; DomainName: string;
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
  var query_606872 = newJObject()
  var formData_606873 = newJObject()
  add(formData_606873, "DomainName", newJString(DomainName))
  add(query_606872, "Action", newJString(Action))
  add(formData_606873, "Stems", newJString(Stems))
  add(query_606872, "Version", newJString(Version))
  result = call_606871.call(nil, query_606872, nil, formData_606873, nil)

var postUpdateStemmingOptions* = Call_PostUpdateStemmingOptions_606856(
    name: "postUpdateStemmingOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateStemmingOptions",
    validator: validate_PostUpdateStemmingOptions_606857, base: "/",
    url: url_PostUpdateStemmingOptions_606858,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateStemmingOptions_606839 = ref object of OpenApiRestCall_605589
proc url_GetUpdateStemmingOptions_606841(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUpdateStemmingOptions_606840(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures a stemming dictionary for the search domain. The stemming dictionary is used during indexing and when processing search requests. The maximum size of the stemming dictionary is 500 KB.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Stems: JString (required)
  ##        : Maps terms to their stems, serialized as a JSON document. The document has a single object with one property "stems" whose value is an object mapping terms to their stems. The maximum size of a stemming document is 500 KB. Example: <code>{ "stems": {"people": "person", "walking": "walk"} }</code>
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `Stems` field"
  var valid_606842 = query.getOrDefault("Stems")
  valid_606842 = validateParameter(valid_606842, JString, required = true,
                                 default = nil)
  if valid_606842 != nil:
    section.add "Stems", valid_606842
  var valid_606843 = query.getOrDefault("DomainName")
  valid_606843 = validateParameter(valid_606843, JString, required = true,
                                 default = nil)
  if valid_606843 != nil:
    section.add "DomainName", valid_606843
  var valid_606844 = query.getOrDefault("Action")
  valid_606844 = validateParameter(valid_606844, JString, required = true,
                                 default = newJString("UpdateStemmingOptions"))
  if valid_606844 != nil:
    section.add "Action", valid_606844
  var valid_606845 = query.getOrDefault("Version")
  valid_606845 = validateParameter(valid_606845, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_606845 != nil:
    section.add "Version", valid_606845
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606846 = header.getOrDefault("X-Amz-Signature")
  valid_606846 = validateParameter(valid_606846, JString, required = false,
                                 default = nil)
  if valid_606846 != nil:
    section.add "X-Amz-Signature", valid_606846
  var valid_606847 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606847 = validateParameter(valid_606847, JString, required = false,
                                 default = nil)
  if valid_606847 != nil:
    section.add "X-Amz-Content-Sha256", valid_606847
  var valid_606848 = header.getOrDefault("X-Amz-Date")
  valid_606848 = validateParameter(valid_606848, JString, required = false,
                                 default = nil)
  if valid_606848 != nil:
    section.add "X-Amz-Date", valid_606848
  var valid_606849 = header.getOrDefault("X-Amz-Credential")
  valid_606849 = validateParameter(valid_606849, JString, required = false,
                                 default = nil)
  if valid_606849 != nil:
    section.add "X-Amz-Credential", valid_606849
  var valid_606850 = header.getOrDefault("X-Amz-Security-Token")
  valid_606850 = validateParameter(valid_606850, JString, required = false,
                                 default = nil)
  if valid_606850 != nil:
    section.add "X-Amz-Security-Token", valid_606850
  var valid_606851 = header.getOrDefault("X-Amz-Algorithm")
  valid_606851 = validateParameter(valid_606851, JString, required = false,
                                 default = nil)
  if valid_606851 != nil:
    section.add "X-Amz-Algorithm", valid_606851
  var valid_606852 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606852 = validateParameter(valid_606852, JString, required = false,
                                 default = nil)
  if valid_606852 != nil:
    section.add "X-Amz-SignedHeaders", valid_606852
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606853: Call_GetUpdateStemmingOptions_606839; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a stemming dictionary for the search domain. The stemming dictionary is used during indexing and when processing search requests. The maximum size of the stemming dictionary is 500 KB.
  ## 
  let valid = call_606853.validator(path, query, header, formData, body)
  let scheme = call_606853.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606853.url(scheme.get, call_606853.host, call_606853.base,
                         call_606853.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606853, url, valid)

proc call*(call_606854: Call_GetUpdateStemmingOptions_606839; Stems: string;
          DomainName: string; Action: string = "UpdateStemmingOptions";
          Version: string = "2011-02-01"): Recallable =
  ## getUpdateStemmingOptions
  ## Configures a stemming dictionary for the search domain. The stemming dictionary is used during indexing and when processing search requests. The maximum size of the stemming dictionary is 500 KB.
  ##   Stems: string (required)
  ##        : Maps terms to their stems, serialized as a JSON document. The document has a single object with one property "stems" whose value is an object mapping terms to their stems. The maximum size of a stemming document is 500 KB. Example: <code>{ "stems": {"people": "person", "walking": "walk"} }</code>
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606855 = newJObject()
  add(query_606855, "Stems", newJString(Stems))
  add(query_606855, "DomainName", newJString(DomainName))
  add(query_606855, "Action", newJString(Action))
  add(query_606855, "Version", newJString(Version))
  result = call_606854.call(nil, query_606855, nil, nil, nil)

var getUpdateStemmingOptions* = Call_GetUpdateStemmingOptions_606839(
    name: "getUpdateStemmingOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateStemmingOptions",
    validator: validate_GetUpdateStemmingOptions_606840, base: "/",
    url: url_GetUpdateStemmingOptions_606841, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateStopwordOptions_606891 = ref object of OpenApiRestCall_605589
proc url_PostUpdateStopwordOptions_606893(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostUpdateStopwordOptions_606892(path: JsonNode; query: JsonNode;
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
  var valid_606894 = query.getOrDefault("Action")
  valid_606894 = validateParameter(valid_606894, JString, required = true,
                                 default = newJString("UpdateStopwordOptions"))
  if valid_606894 != nil:
    section.add "Action", valid_606894
  var valid_606895 = query.getOrDefault("Version")
  valid_606895 = validateParameter(valid_606895, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_606895 != nil:
    section.add "Version", valid_606895
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606896 = header.getOrDefault("X-Amz-Signature")
  valid_606896 = validateParameter(valid_606896, JString, required = false,
                                 default = nil)
  if valid_606896 != nil:
    section.add "X-Amz-Signature", valid_606896
  var valid_606897 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606897 = validateParameter(valid_606897, JString, required = false,
                                 default = nil)
  if valid_606897 != nil:
    section.add "X-Amz-Content-Sha256", valid_606897
  var valid_606898 = header.getOrDefault("X-Amz-Date")
  valid_606898 = validateParameter(valid_606898, JString, required = false,
                                 default = nil)
  if valid_606898 != nil:
    section.add "X-Amz-Date", valid_606898
  var valid_606899 = header.getOrDefault("X-Amz-Credential")
  valid_606899 = validateParameter(valid_606899, JString, required = false,
                                 default = nil)
  if valid_606899 != nil:
    section.add "X-Amz-Credential", valid_606899
  var valid_606900 = header.getOrDefault("X-Amz-Security-Token")
  valid_606900 = validateParameter(valid_606900, JString, required = false,
                                 default = nil)
  if valid_606900 != nil:
    section.add "X-Amz-Security-Token", valid_606900
  var valid_606901 = header.getOrDefault("X-Amz-Algorithm")
  valid_606901 = validateParameter(valid_606901, JString, required = false,
                                 default = nil)
  if valid_606901 != nil:
    section.add "X-Amz-Algorithm", valid_606901
  var valid_606902 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606902 = validateParameter(valid_606902, JString, required = false,
                                 default = nil)
  if valid_606902 != nil:
    section.add "X-Amz-SignedHeaders", valid_606902
  result.add "header", section
  ## parameters in `formData` object:
  ##   Stopwords: JString (required)
  ##            : Lists stopwords serialized as a JSON document. The document has a single object with one property "stopwords" whose value is an array of strings. The maximum size of a stopwords document is 10 KB. Example: <code>{ "stopwords": ["a", "an", "the", "of"] }</code>
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Stopwords` field"
  var valid_606903 = formData.getOrDefault("Stopwords")
  valid_606903 = validateParameter(valid_606903, JString, required = true,
                                 default = nil)
  if valid_606903 != nil:
    section.add "Stopwords", valid_606903
  var valid_606904 = formData.getOrDefault("DomainName")
  valid_606904 = validateParameter(valid_606904, JString, required = true,
                                 default = nil)
  if valid_606904 != nil:
    section.add "DomainName", valid_606904
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606905: Call_PostUpdateStopwordOptions_606891; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures stopwords for the search domain. Stopwords are used during indexing and when processing search requests. The maximum size of the stopwords dictionary is 10 KB.
  ## 
  let valid = call_606905.validator(path, query, header, formData, body)
  let scheme = call_606905.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606905.url(scheme.get, call_606905.host, call_606905.base,
                         call_606905.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606905, url, valid)

proc call*(call_606906: Call_PostUpdateStopwordOptions_606891; Stopwords: string;
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
  var query_606907 = newJObject()
  var formData_606908 = newJObject()
  add(formData_606908, "Stopwords", newJString(Stopwords))
  add(formData_606908, "DomainName", newJString(DomainName))
  add(query_606907, "Action", newJString(Action))
  add(query_606907, "Version", newJString(Version))
  result = call_606906.call(nil, query_606907, nil, formData_606908, nil)

var postUpdateStopwordOptions* = Call_PostUpdateStopwordOptions_606891(
    name: "postUpdateStopwordOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateStopwordOptions",
    validator: validate_PostUpdateStopwordOptions_606892, base: "/",
    url: url_PostUpdateStopwordOptions_606893,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateStopwordOptions_606874 = ref object of OpenApiRestCall_605589
proc url_GetUpdateStopwordOptions_606876(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUpdateStopwordOptions_606875(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures stopwords for the search domain. Stopwords are used during indexing and when processing search requests. The maximum size of the stopwords dictionary is 10 KB.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Stopwords: JString (required)
  ##            : Lists stopwords serialized as a JSON document. The document has a single object with one property "stopwords" whose value is an array of strings. The maximum size of a stopwords document is 10 KB. Example: <code>{ "stopwords": ["a", "an", "the", "of"] }</code>
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Stopwords` field"
  var valid_606877 = query.getOrDefault("Stopwords")
  valid_606877 = validateParameter(valid_606877, JString, required = true,
                                 default = nil)
  if valid_606877 != nil:
    section.add "Stopwords", valid_606877
  var valid_606878 = query.getOrDefault("DomainName")
  valid_606878 = validateParameter(valid_606878, JString, required = true,
                                 default = nil)
  if valid_606878 != nil:
    section.add "DomainName", valid_606878
  var valid_606879 = query.getOrDefault("Action")
  valid_606879 = validateParameter(valid_606879, JString, required = true,
                                 default = newJString("UpdateStopwordOptions"))
  if valid_606879 != nil:
    section.add "Action", valid_606879
  var valid_606880 = query.getOrDefault("Version")
  valid_606880 = validateParameter(valid_606880, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_606880 != nil:
    section.add "Version", valid_606880
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606881 = header.getOrDefault("X-Amz-Signature")
  valid_606881 = validateParameter(valid_606881, JString, required = false,
                                 default = nil)
  if valid_606881 != nil:
    section.add "X-Amz-Signature", valid_606881
  var valid_606882 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606882 = validateParameter(valid_606882, JString, required = false,
                                 default = nil)
  if valid_606882 != nil:
    section.add "X-Amz-Content-Sha256", valid_606882
  var valid_606883 = header.getOrDefault("X-Amz-Date")
  valid_606883 = validateParameter(valid_606883, JString, required = false,
                                 default = nil)
  if valid_606883 != nil:
    section.add "X-Amz-Date", valid_606883
  var valid_606884 = header.getOrDefault("X-Amz-Credential")
  valid_606884 = validateParameter(valid_606884, JString, required = false,
                                 default = nil)
  if valid_606884 != nil:
    section.add "X-Amz-Credential", valid_606884
  var valid_606885 = header.getOrDefault("X-Amz-Security-Token")
  valid_606885 = validateParameter(valid_606885, JString, required = false,
                                 default = nil)
  if valid_606885 != nil:
    section.add "X-Amz-Security-Token", valid_606885
  var valid_606886 = header.getOrDefault("X-Amz-Algorithm")
  valid_606886 = validateParameter(valid_606886, JString, required = false,
                                 default = nil)
  if valid_606886 != nil:
    section.add "X-Amz-Algorithm", valid_606886
  var valid_606887 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606887 = validateParameter(valid_606887, JString, required = false,
                                 default = nil)
  if valid_606887 != nil:
    section.add "X-Amz-SignedHeaders", valid_606887
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606888: Call_GetUpdateStopwordOptions_606874; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures stopwords for the search domain. Stopwords are used during indexing and when processing search requests. The maximum size of the stopwords dictionary is 10 KB.
  ## 
  let valid = call_606888.validator(path, query, header, formData, body)
  let scheme = call_606888.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606888.url(scheme.get, call_606888.host, call_606888.base,
                         call_606888.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606888, url, valid)

proc call*(call_606889: Call_GetUpdateStopwordOptions_606874; Stopwords: string;
          DomainName: string; Action: string = "UpdateStopwordOptions";
          Version: string = "2011-02-01"): Recallable =
  ## getUpdateStopwordOptions
  ## Configures stopwords for the search domain. Stopwords are used during indexing and when processing search requests. The maximum size of the stopwords dictionary is 10 KB.
  ##   Stopwords: string (required)
  ##            : Lists stopwords serialized as a JSON document. The document has a single object with one property "stopwords" whose value is an array of strings. The maximum size of a stopwords document is 10 KB. Example: <code>{ "stopwords": ["a", "an", "the", "of"] }</code>
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606890 = newJObject()
  add(query_606890, "Stopwords", newJString(Stopwords))
  add(query_606890, "DomainName", newJString(DomainName))
  add(query_606890, "Action", newJString(Action))
  add(query_606890, "Version", newJString(Version))
  result = call_606889.call(nil, query_606890, nil, nil, nil)

var getUpdateStopwordOptions* = Call_GetUpdateStopwordOptions_606874(
    name: "getUpdateStopwordOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateStopwordOptions",
    validator: validate_GetUpdateStopwordOptions_606875, base: "/",
    url: url_GetUpdateStopwordOptions_606876, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateSynonymOptions_606926 = ref object of OpenApiRestCall_605589
proc url_PostUpdateSynonymOptions_606928(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostUpdateSynonymOptions_606927(path: JsonNode; query: JsonNode;
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
  var valid_606929 = query.getOrDefault("Action")
  valid_606929 = validateParameter(valid_606929, JString, required = true,
                                 default = newJString("UpdateSynonymOptions"))
  if valid_606929 != nil:
    section.add "Action", valid_606929
  var valid_606930 = query.getOrDefault("Version")
  valid_606930 = validateParameter(valid_606930, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_606930 != nil:
    section.add "Version", valid_606930
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606931 = header.getOrDefault("X-Amz-Signature")
  valid_606931 = validateParameter(valid_606931, JString, required = false,
                                 default = nil)
  if valid_606931 != nil:
    section.add "X-Amz-Signature", valid_606931
  var valid_606932 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606932 = validateParameter(valid_606932, JString, required = false,
                                 default = nil)
  if valid_606932 != nil:
    section.add "X-Amz-Content-Sha256", valid_606932
  var valid_606933 = header.getOrDefault("X-Amz-Date")
  valid_606933 = validateParameter(valid_606933, JString, required = false,
                                 default = nil)
  if valid_606933 != nil:
    section.add "X-Amz-Date", valid_606933
  var valid_606934 = header.getOrDefault("X-Amz-Credential")
  valid_606934 = validateParameter(valid_606934, JString, required = false,
                                 default = nil)
  if valid_606934 != nil:
    section.add "X-Amz-Credential", valid_606934
  var valid_606935 = header.getOrDefault("X-Amz-Security-Token")
  valid_606935 = validateParameter(valid_606935, JString, required = false,
                                 default = nil)
  if valid_606935 != nil:
    section.add "X-Amz-Security-Token", valid_606935
  var valid_606936 = header.getOrDefault("X-Amz-Algorithm")
  valid_606936 = validateParameter(valid_606936, JString, required = false,
                                 default = nil)
  if valid_606936 != nil:
    section.add "X-Amz-Algorithm", valid_606936
  var valid_606937 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606937 = validateParameter(valid_606937, JString, required = false,
                                 default = nil)
  if valid_606937 != nil:
    section.add "X-Amz-SignedHeaders", valid_606937
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Synonyms: JString (required)
  ##           : Maps terms to their synonyms, serialized as a JSON document. The document has a single object with one property "synonyms" whose value is an object mapping terms to their synonyms. Each synonym is a simple string or an array of strings. The maximum size of a stopwords document is 100 KB. Example: <code>{ "synonyms": {"cat": ["feline", "kitten"], "puppy": "dog"} }</code>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_606938 = formData.getOrDefault("DomainName")
  valid_606938 = validateParameter(valid_606938, JString, required = true,
                                 default = nil)
  if valid_606938 != nil:
    section.add "DomainName", valid_606938
  var valid_606939 = formData.getOrDefault("Synonyms")
  valid_606939 = validateParameter(valid_606939, JString, required = true,
                                 default = nil)
  if valid_606939 != nil:
    section.add "Synonyms", valid_606939
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606940: Call_PostUpdateSynonymOptions_606926; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a synonym dictionary for the search domain. The synonym dictionary is used during indexing to configure mappings for terms that occur in text fields. The maximum size of the synonym dictionary is 100 KB. 
  ## 
  let valid = call_606940.validator(path, query, header, formData, body)
  let scheme = call_606940.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606940.url(scheme.get, call_606940.host, call_606940.base,
                         call_606940.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606940, url, valid)

proc call*(call_606941: Call_PostUpdateSynonymOptions_606926; DomainName: string;
          Synonyms: string; Action: string = "UpdateSynonymOptions";
          Version: string = "2011-02-01"): Recallable =
  ## postUpdateSynonymOptions
  ## Configures a synonym dictionary for the search domain. The synonym dictionary is used during indexing to configure mappings for terms that occur in text fields. The maximum size of the synonym dictionary is 100 KB. 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Synonyms: string (required)
  ##           : Maps terms to their synonyms, serialized as a JSON document. The document has a single object with one property "synonyms" whose value is an object mapping terms to their synonyms. Each synonym is a simple string or an array of strings. The maximum size of a stopwords document is 100 KB. Example: <code>{ "synonyms": {"cat": ["feline", "kitten"], "puppy": "dog"} }</code>
  ##   Version: string (required)
  var query_606942 = newJObject()
  var formData_606943 = newJObject()
  add(formData_606943, "DomainName", newJString(DomainName))
  add(query_606942, "Action", newJString(Action))
  add(formData_606943, "Synonyms", newJString(Synonyms))
  add(query_606942, "Version", newJString(Version))
  result = call_606941.call(nil, query_606942, nil, formData_606943, nil)

var postUpdateSynonymOptions* = Call_PostUpdateSynonymOptions_606926(
    name: "postUpdateSynonymOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateSynonymOptions",
    validator: validate_PostUpdateSynonymOptions_606927, base: "/",
    url: url_PostUpdateSynonymOptions_606928, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateSynonymOptions_606909 = ref object of OpenApiRestCall_605589
proc url_GetUpdateSynonymOptions_606911(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUpdateSynonymOptions_606910(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Configures a synonym dictionary for the search domain. The synonym dictionary is used during indexing to configure mappings for terms that occur in text fields. The maximum size of the synonym dictionary is 100 KB. 
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   Synonyms: JString (required)
  ##           : Maps terms to their synonyms, serialized as a JSON document. The document has a single object with one property "synonyms" whose value is an object mapping terms to their synonyms. Each synonym is a simple string or an array of strings. The maximum size of a stopwords document is 100 KB. Example: <code>{ "synonyms": {"cat": ["feline", "kitten"], "puppy": "dog"} }</code>
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: JString (required)
  ##   Version: JString (required)
  section = newJObject()
  assert query != nil,
        "query argument is necessary due to required `Synonyms` field"
  var valid_606912 = query.getOrDefault("Synonyms")
  valid_606912 = validateParameter(valid_606912, JString, required = true,
                                 default = nil)
  if valid_606912 != nil:
    section.add "Synonyms", valid_606912
  var valid_606913 = query.getOrDefault("DomainName")
  valid_606913 = validateParameter(valid_606913, JString, required = true,
                                 default = nil)
  if valid_606913 != nil:
    section.add "DomainName", valid_606913
  var valid_606914 = query.getOrDefault("Action")
  valid_606914 = validateParameter(valid_606914, JString, required = true,
                                 default = newJString("UpdateSynonymOptions"))
  if valid_606914 != nil:
    section.add "Action", valid_606914
  var valid_606915 = query.getOrDefault("Version")
  valid_606915 = validateParameter(valid_606915, JString, required = true,
                                 default = newJString("2011-02-01"))
  if valid_606915 != nil:
    section.add "Version", valid_606915
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606916 = header.getOrDefault("X-Amz-Signature")
  valid_606916 = validateParameter(valid_606916, JString, required = false,
                                 default = nil)
  if valid_606916 != nil:
    section.add "X-Amz-Signature", valid_606916
  var valid_606917 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606917 = validateParameter(valid_606917, JString, required = false,
                                 default = nil)
  if valid_606917 != nil:
    section.add "X-Amz-Content-Sha256", valid_606917
  var valid_606918 = header.getOrDefault("X-Amz-Date")
  valid_606918 = validateParameter(valid_606918, JString, required = false,
                                 default = nil)
  if valid_606918 != nil:
    section.add "X-Amz-Date", valid_606918
  var valid_606919 = header.getOrDefault("X-Amz-Credential")
  valid_606919 = validateParameter(valid_606919, JString, required = false,
                                 default = nil)
  if valid_606919 != nil:
    section.add "X-Amz-Credential", valid_606919
  var valid_606920 = header.getOrDefault("X-Amz-Security-Token")
  valid_606920 = validateParameter(valid_606920, JString, required = false,
                                 default = nil)
  if valid_606920 != nil:
    section.add "X-Amz-Security-Token", valid_606920
  var valid_606921 = header.getOrDefault("X-Amz-Algorithm")
  valid_606921 = validateParameter(valid_606921, JString, required = false,
                                 default = nil)
  if valid_606921 != nil:
    section.add "X-Amz-Algorithm", valid_606921
  var valid_606922 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606922 = validateParameter(valid_606922, JString, required = false,
                                 default = nil)
  if valid_606922 != nil:
    section.add "X-Amz-SignedHeaders", valid_606922
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606923: Call_GetUpdateSynonymOptions_606909; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Configures a synonym dictionary for the search domain. The synonym dictionary is used during indexing to configure mappings for terms that occur in text fields. The maximum size of the synonym dictionary is 100 KB. 
  ## 
  let valid = call_606923.validator(path, query, header, formData, body)
  let scheme = call_606923.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606923.url(scheme.get, call_606923.host, call_606923.base,
                         call_606923.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606923, url, valid)

proc call*(call_606924: Call_GetUpdateSynonymOptions_606909; Synonyms: string;
          DomainName: string; Action: string = "UpdateSynonymOptions";
          Version: string = "2011-02-01"): Recallable =
  ## getUpdateSynonymOptions
  ## Configures a synonym dictionary for the search domain. The synonym dictionary is used during indexing to configure mappings for terms that occur in text fields. The maximum size of the synonym dictionary is 100 KB. 
  ##   Synonyms: string (required)
  ##           : Maps terms to their synonyms, serialized as a JSON document. The document has a single object with one property "synonyms" whose value is an object mapping terms to their synonyms. Each synonym is a simple string or an array of strings. The maximum size of a stopwords document is 100 KB. Example: <code>{ "synonyms": {"cat": ["feline", "kitten"], "puppy": "dog"} }</code>
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_606925 = newJObject()
  add(query_606925, "Synonyms", newJString(Synonyms))
  add(query_606925, "DomainName", newJString(DomainName))
  add(query_606925, "Action", newJString(Action))
  add(query_606925, "Version", newJString(Version))
  result = call_606924.call(nil, query_606925, nil, nil, nil)

var getUpdateSynonymOptions* = Call_GetUpdateSynonymOptions_606909(
    name: "getUpdateSynonymOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateSynonymOptions",
    validator: validate_GetUpdateSynonymOptions_606910, base: "/",
    url: url_GetUpdateSynonymOptions_606911, schemes: {Scheme.Https, Scheme.Http})
export
  rest

type
  EnvKind = enum
    BakeIntoBinary = "Baking $1 into the binary",
    FetchFromEnv = "Fetch $1 from the environment"
template sloppyConst(via: EnvKind; name: untyped): untyped =
  import
    macros

  const
    name {.strdefine.}: string = case via
    of BakeIntoBinary:
      getEnv(astToStr(name), "")
    of FetchFromEnv:
      ""
  static :
    let msg = block:
      if name == "":
        "Missing $1 in the environment"
      else:
        $via
    warning msg % [astToStr(name)]

sloppyConst FetchFromEnv, AWS_ACCESS_KEY_ID
sloppyConst FetchFromEnv, AWS_SECRET_ACCESS_KEY
sloppyConst BakeIntoBinary, AWS_REGION
sloppyConst FetchFromEnv, AWS_ACCOUNT_ID
proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", AWS_ACCESS_KEY_ID)
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", AWS_SECRET_ACCESS_KEY)
    region = os.getEnv("AWS_REGION", AWS_REGION)
  assert secret != "", "need $AWS_SECRET_ACCESS_KEY in environment"
  assert access != "", "need $AWS_ACCESS_KEY_ID in environment"
  assert region != "", "need $AWS_REGION in environment"
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

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  ## the hook is a terrible earworm
  var headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
  let
    body = input.getOrDefault("body")
    text = if body == nil:
      "" elif body.kind == JString:
      body.getStr else:
      $body
  if body != nil and body.kind != JString:
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  const
    XAmzSecurityToken = "X-Amz-Security-Token"
  if not headers.hasKey(XAmzSecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[XAmzSecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
