
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

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
  ValidatorSignature = proc (path: JsonNode = nil; query: JsonNode = nil;
                          header: JsonNode = nil; formData: JsonNode = nil;
                          body: JsonNode = nil; _: string = ""): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    makeUrl*: proc (protocol: Scheme; host: string; base: string; route: string;
                  path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_21625435 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_21625435](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_21625435): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low .. Scheme.high:
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
  if js == nil:
    if required:
      if default != nil:
        return validateParameter(default, kind, required = required)
  result = js
  if result == nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind == kind, $kind & " expected; received " & $js.kind

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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_PostCreateDomain_21626034 = ref object of OpenApiRestCall_21625435
proc url_PostCreateDomain_21626036(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostCreateDomain_21626035(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626037 = query.getOrDefault("Action")
  valid_21626037 = validateParameter(valid_21626037, JString, required = true,
                                   default = newJString("CreateDomain"))
  if valid_21626037 != nil:
    section.add "Action", valid_21626037
  var valid_21626038 = query.getOrDefault("Version")
  valid_21626038 = validateParameter(valid_21626038, JString, required = true,
                                   default = newJString("2011-02-01"))
  if valid_21626038 != nil:
    section.add "Version", valid_21626038
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
  var valid_21626039 = header.getOrDefault("X-Amz-Date")
  valid_21626039 = validateParameter(valid_21626039, JString, required = false,
                                   default = nil)
  if valid_21626039 != nil:
    section.add "X-Amz-Date", valid_21626039
  var valid_21626040 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626040 = validateParameter(valid_21626040, JString, required = false,
                                   default = nil)
  if valid_21626040 != nil:
    section.add "X-Amz-Security-Token", valid_21626040
  var valid_21626041 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626041 = validateParameter(valid_21626041, JString, required = false,
                                   default = nil)
  if valid_21626041 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626041
  var valid_21626042 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626042 = validateParameter(valid_21626042, JString, required = false,
                                   default = nil)
  if valid_21626042 != nil:
    section.add "X-Amz-Algorithm", valid_21626042
  var valid_21626043 = header.getOrDefault("X-Amz-Signature")
  valid_21626043 = validateParameter(valid_21626043, JString, required = false,
                                   default = nil)
  if valid_21626043 != nil:
    section.add "X-Amz-Signature", valid_21626043
  var valid_21626044 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626044 = validateParameter(valid_21626044, JString, required = false,
                                   default = nil)
  if valid_21626044 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626044
  var valid_21626045 = header.getOrDefault("X-Amz-Credential")
  valid_21626045 = validateParameter(valid_21626045, JString, required = false,
                                   default = nil)
  if valid_21626045 != nil:
    section.add "X-Amz-Credential", valid_21626045
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_21626046 = formData.getOrDefault("DomainName")
  valid_21626046 = validateParameter(valid_21626046, JString, required = true,
                                   default = nil)
  if valid_21626046 != nil:
    section.add "DomainName", valid_21626046
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626047: Call_PostCreateDomain_21626034; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new search domain.
  ## 
  let valid = call_21626047.validator(path, query, header, formData, body, _)
  let scheme = call_21626047.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626047.makeUrl(scheme.get, call_21626047.host, call_21626047.base,
                               call_21626047.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626047, uri, valid, _)

proc call*(call_21626048: Call_PostCreateDomain_21626034; DomainName: string;
          Action: string = "CreateDomain"; Version: string = "2011-02-01"): Recallable =
  ## postCreateDomain
  ## Creates a new search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626049 = newJObject()
  var formData_21626050 = newJObject()
  add(formData_21626050, "DomainName", newJString(DomainName))
  add(query_21626049, "Action", newJString(Action))
  add(query_21626049, "Version", newJString(Version))
  result = call_21626048.call(nil, query_21626049, nil, formData_21626050, nil)

var postCreateDomain* = Call_PostCreateDomain_21626034(name: "postCreateDomain",
    meth: HttpMethod.HttpPost, host: "cloudsearch.amazonaws.com",
    route: "/#Action=CreateDomain", validator: validate_PostCreateDomain_21626035,
    base: "/", makeUrl: url_PostCreateDomain_21626036,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCreateDomain_21625779 = ref object of OpenApiRestCall_21625435
proc url_GetCreateDomain_21625781(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCreateDomain_21625780(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21625896 = query.getOrDefault("Action")
  valid_21625896 = validateParameter(valid_21625896, JString, required = true,
                                   default = newJString("CreateDomain"))
  if valid_21625896 != nil:
    section.add "Action", valid_21625896
  var valid_21625897 = query.getOrDefault("DomainName")
  valid_21625897 = validateParameter(valid_21625897, JString, required = true,
                                   default = nil)
  if valid_21625897 != nil:
    section.add "DomainName", valid_21625897
  var valid_21625898 = query.getOrDefault("Version")
  valid_21625898 = validateParameter(valid_21625898, JString, required = true,
                                   default = newJString("2011-02-01"))
  if valid_21625898 != nil:
    section.add "Version", valid_21625898
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
  var valid_21625899 = header.getOrDefault("X-Amz-Date")
  valid_21625899 = validateParameter(valid_21625899, JString, required = false,
                                   default = nil)
  if valid_21625899 != nil:
    section.add "X-Amz-Date", valid_21625899
  var valid_21625900 = header.getOrDefault("X-Amz-Security-Token")
  valid_21625900 = validateParameter(valid_21625900, JString, required = false,
                                   default = nil)
  if valid_21625900 != nil:
    section.add "X-Amz-Security-Token", valid_21625900
  var valid_21625901 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625901 = validateParameter(valid_21625901, JString, required = false,
                                   default = nil)
  if valid_21625901 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625901
  var valid_21625902 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625902 = validateParameter(valid_21625902, JString, required = false,
                                   default = nil)
  if valid_21625902 != nil:
    section.add "X-Amz-Algorithm", valid_21625902
  var valid_21625903 = header.getOrDefault("X-Amz-Signature")
  valid_21625903 = validateParameter(valid_21625903, JString, required = false,
                                   default = nil)
  if valid_21625903 != nil:
    section.add "X-Amz-Signature", valid_21625903
  var valid_21625904 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21625904 = validateParameter(valid_21625904, JString, required = false,
                                   default = nil)
  if valid_21625904 != nil:
    section.add "X-Amz-SignedHeaders", valid_21625904
  var valid_21625905 = header.getOrDefault("X-Amz-Credential")
  valid_21625905 = validateParameter(valid_21625905, JString, required = false,
                                   default = nil)
  if valid_21625905 != nil:
    section.add "X-Amz-Credential", valid_21625905
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21625930: Call_GetCreateDomain_21625779; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new search domain.
  ## 
  let valid = call_21625930.validator(path, query, header, formData, body, _)
  let scheme = call_21625930.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625930.makeUrl(scheme.get, call_21625930.host, call_21625930.base,
                               call_21625930.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625930, uri, valid, _)

proc call*(call_21625993: Call_GetCreateDomain_21625779; DomainName: string;
          Action: string = "CreateDomain"; Version: string = "2011-02-01"): Recallable =
  ## getCreateDomain
  ## Creates a new search domain.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_21625995 = newJObject()
  add(query_21625995, "Action", newJString(Action))
  add(query_21625995, "DomainName", newJString(DomainName))
  add(query_21625995, "Version", newJString(Version))
  result = call_21625993.call(nil, query_21625995, nil, nil, nil)

var getCreateDomain* = Call_GetCreateDomain_21625779(name: "getCreateDomain",
    meth: HttpMethod.HttpGet, host: "cloudsearch.amazonaws.com",
    route: "/#Action=CreateDomain", validator: validate_GetCreateDomain_21625780,
    base: "/", makeUrl: url_GetCreateDomain_21625781,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDefineIndexField_21626074 = ref object of OpenApiRestCall_21625435
proc url_PostDefineIndexField_21626076(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDefineIndexField_21626075(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626077 = query.getOrDefault("Action")
  valid_21626077 = validateParameter(valid_21626077, JString, required = true,
                                   default = newJString("DefineIndexField"))
  if valid_21626077 != nil:
    section.add "Action", valid_21626077
  var valid_21626078 = query.getOrDefault("Version")
  valid_21626078 = validateParameter(valid_21626078, JString, required = true,
                                   default = newJString("2011-02-01"))
  if valid_21626078 != nil:
    section.add "Version", valid_21626078
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
  var valid_21626079 = header.getOrDefault("X-Amz-Date")
  valid_21626079 = validateParameter(valid_21626079, JString, required = false,
                                   default = nil)
  if valid_21626079 != nil:
    section.add "X-Amz-Date", valid_21626079
  var valid_21626080 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626080 = validateParameter(valid_21626080, JString, required = false,
                                   default = nil)
  if valid_21626080 != nil:
    section.add "X-Amz-Security-Token", valid_21626080
  var valid_21626081 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626081 = validateParameter(valid_21626081, JString, required = false,
                                   default = nil)
  if valid_21626081 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626081
  var valid_21626082 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626082 = validateParameter(valid_21626082, JString, required = false,
                                   default = nil)
  if valid_21626082 != nil:
    section.add "X-Amz-Algorithm", valid_21626082
  var valid_21626083 = header.getOrDefault("X-Amz-Signature")
  valid_21626083 = validateParameter(valid_21626083, JString, required = false,
                                   default = nil)
  if valid_21626083 != nil:
    section.add "X-Amz-Signature", valid_21626083
  var valid_21626084 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626084 = validateParameter(valid_21626084, JString, required = false,
                                   default = nil)
  if valid_21626084 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626084
  var valid_21626085 = header.getOrDefault("X-Amz-Credential")
  valid_21626085 = validateParameter(valid_21626085, JString, required = false,
                                   default = nil)
  if valid_21626085 != nil:
    section.add "X-Amz-Credential", valid_21626085
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
  var valid_21626086 = formData.getOrDefault("IndexField.UIntOptions")
  valid_21626086 = validateParameter(valid_21626086, JString, required = false,
                                   default = nil)
  if valid_21626086 != nil:
    section.add "IndexField.UIntOptions", valid_21626086
  var valid_21626087 = formData.getOrDefault("IndexField.TextOptions")
  valid_21626087 = validateParameter(valid_21626087, JString, required = false,
                                   default = nil)
  if valid_21626087 != nil:
    section.add "IndexField.TextOptions", valid_21626087
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_21626088 = formData.getOrDefault("DomainName")
  valid_21626088 = validateParameter(valid_21626088, JString, required = true,
                                   default = nil)
  if valid_21626088 != nil:
    section.add "DomainName", valid_21626088
  var valid_21626089 = formData.getOrDefault("IndexField.LiteralOptions")
  valid_21626089 = validateParameter(valid_21626089, JString, required = false,
                                   default = nil)
  if valid_21626089 != nil:
    section.add "IndexField.LiteralOptions", valid_21626089
  var valid_21626090 = formData.getOrDefault("IndexField.IndexFieldType")
  valid_21626090 = validateParameter(valid_21626090, JString, required = false,
                                   default = nil)
  if valid_21626090 != nil:
    section.add "IndexField.IndexFieldType", valid_21626090
  var valid_21626091 = formData.getOrDefault("IndexField.IndexFieldName")
  valid_21626091 = validateParameter(valid_21626091, JString, required = false,
                                   default = nil)
  if valid_21626091 != nil:
    section.add "IndexField.IndexFieldName", valid_21626091
  var valid_21626092 = formData.getOrDefault("IndexField.SourceAttributes")
  valid_21626092 = validateParameter(valid_21626092, JArray, required = false,
                                   default = nil)
  if valid_21626092 != nil:
    section.add "IndexField.SourceAttributes", valid_21626092
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626093: Call_PostDefineIndexField_21626074; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Configures an <code>IndexField</code> for the search domain. Used to create new fields and modify existing ones. If the field exists, the new configuration replaces the old one. You can configure a maximum of 200 index fields.
  ## 
  let valid = call_21626093.validator(path, query, header, formData, body, _)
  let scheme = call_21626093.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626093.makeUrl(scheme.get, call_21626093.host, call_21626093.base,
                               call_21626093.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626093, uri, valid, _)

proc call*(call_21626094: Call_PostDefineIndexField_21626074; DomainName: string;
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
  var query_21626095 = newJObject()
  var formData_21626096 = newJObject()
  add(formData_21626096, "IndexField.UIntOptions",
      newJString(IndexFieldUIntOptions))
  add(formData_21626096, "IndexField.TextOptions",
      newJString(IndexFieldTextOptions))
  add(formData_21626096, "DomainName", newJString(DomainName))
  add(formData_21626096, "IndexField.LiteralOptions",
      newJString(IndexFieldLiteralOptions))
  add(formData_21626096, "IndexField.IndexFieldType",
      newJString(IndexFieldIndexFieldType))
  add(query_21626095, "Action", newJString(Action))
  add(formData_21626096, "IndexField.IndexFieldName",
      newJString(IndexFieldIndexFieldName))
  add(query_21626095, "Version", newJString(Version))
  if IndexFieldSourceAttributes != nil:
    formData_21626096.add "IndexField.SourceAttributes",
                         IndexFieldSourceAttributes
  result = call_21626094.call(nil, query_21626095, nil, formData_21626096, nil)

var postDefineIndexField* = Call_PostDefineIndexField_21626074(
    name: "postDefineIndexField", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineIndexField",
    validator: validate_PostDefineIndexField_21626075, base: "/",
    makeUrl: url_PostDefineIndexField_21626076,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDefineIndexField_21626051 = ref object of OpenApiRestCall_21625435
proc url_GetDefineIndexField_21626053(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDefineIndexField_21626052(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626054 = query.getOrDefault("IndexField.TextOptions")
  valid_21626054 = validateParameter(valid_21626054, JString, required = false,
                                   default = nil)
  if valid_21626054 != nil:
    section.add "IndexField.TextOptions", valid_21626054
  var valid_21626055 = query.getOrDefault("IndexField.LiteralOptions")
  valid_21626055 = validateParameter(valid_21626055, JString, required = false,
                                   default = nil)
  if valid_21626055 != nil:
    section.add "IndexField.LiteralOptions", valid_21626055
  var valid_21626056 = query.getOrDefault("IndexField.UIntOptions")
  valid_21626056 = validateParameter(valid_21626056, JString, required = false,
                                   default = nil)
  if valid_21626056 != nil:
    section.add "IndexField.UIntOptions", valid_21626056
  var valid_21626057 = query.getOrDefault("IndexField.IndexFieldType")
  valid_21626057 = validateParameter(valid_21626057, JString, required = false,
                                   default = nil)
  if valid_21626057 != nil:
    section.add "IndexField.IndexFieldType", valid_21626057
  var valid_21626058 = query.getOrDefault("IndexField.SourceAttributes")
  valid_21626058 = validateParameter(valid_21626058, JArray, required = false,
                                   default = nil)
  if valid_21626058 != nil:
    section.add "IndexField.SourceAttributes", valid_21626058
  var valid_21626059 = query.getOrDefault("IndexField.IndexFieldName")
  valid_21626059 = validateParameter(valid_21626059, JString, required = false,
                                   default = nil)
  if valid_21626059 != nil:
    section.add "IndexField.IndexFieldName", valid_21626059
  var valid_21626060 = query.getOrDefault("Action")
  valid_21626060 = validateParameter(valid_21626060, JString, required = true,
                                   default = newJString("DefineIndexField"))
  if valid_21626060 != nil:
    section.add "Action", valid_21626060
  var valid_21626061 = query.getOrDefault("DomainName")
  valid_21626061 = validateParameter(valid_21626061, JString, required = true,
                                   default = nil)
  if valid_21626061 != nil:
    section.add "DomainName", valid_21626061
  var valid_21626062 = query.getOrDefault("Version")
  valid_21626062 = validateParameter(valid_21626062, JString, required = true,
                                   default = newJString("2011-02-01"))
  if valid_21626062 != nil:
    section.add "Version", valid_21626062
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
  var valid_21626063 = header.getOrDefault("X-Amz-Date")
  valid_21626063 = validateParameter(valid_21626063, JString, required = false,
                                   default = nil)
  if valid_21626063 != nil:
    section.add "X-Amz-Date", valid_21626063
  var valid_21626064 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626064 = validateParameter(valid_21626064, JString, required = false,
                                   default = nil)
  if valid_21626064 != nil:
    section.add "X-Amz-Security-Token", valid_21626064
  var valid_21626065 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626065 = validateParameter(valid_21626065, JString, required = false,
                                   default = nil)
  if valid_21626065 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626065
  var valid_21626066 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626066 = validateParameter(valid_21626066, JString, required = false,
                                   default = nil)
  if valid_21626066 != nil:
    section.add "X-Amz-Algorithm", valid_21626066
  var valid_21626067 = header.getOrDefault("X-Amz-Signature")
  valid_21626067 = validateParameter(valid_21626067, JString, required = false,
                                   default = nil)
  if valid_21626067 != nil:
    section.add "X-Amz-Signature", valid_21626067
  var valid_21626068 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626068 = validateParameter(valid_21626068, JString, required = false,
                                   default = nil)
  if valid_21626068 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626068
  var valid_21626069 = header.getOrDefault("X-Amz-Credential")
  valid_21626069 = validateParameter(valid_21626069, JString, required = false,
                                   default = nil)
  if valid_21626069 != nil:
    section.add "X-Amz-Credential", valid_21626069
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626070: Call_GetDefineIndexField_21626051; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Configures an <code>IndexField</code> for the search domain. Used to create new fields and modify existing ones. If the field exists, the new configuration replaces the old one. You can configure a maximum of 200 index fields.
  ## 
  let valid = call_21626070.validator(path, query, header, formData, body, _)
  let scheme = call_21626070.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626070.makeUrl(scheme.get, call_21626070.host, call_21626070.base,
                               call_21626070.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626070, uri, valid, _)

proc call*(call_21626071: Call_GetDefineIndexField_21626051; DomainName: string;
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
  var query_21626072 = newJObject()
  add(query_21626072, "IndexField.TextOptions", newJString(IndexFieldTextOptions))
  add(query_21626072, "IndexField.LiteralOptions",
      newJString(IndexFieldLiteralOptions))
  add(query_21626072, "IndexField.UIntOptions", newJString(IndexFieldUIntOptions))
  add(query_21626072, "IndexField.IndexFieldType",
      newJString(IndexFieldIndexFieldType))
  if IndexFieldSourceAttributes != nil:
    query_21626072.add "IndexField.SourceAttributes", IndexFieldSourceAttributes
  add(query_21626072, "IndexField.IndexFieldName",
      newJString(IndexFieldIndexFieldName))
  add(query_21626072, "Action", newJString(Action))
  add(query_21626072, "DomainName", newJString(DomainName))
  add(query_21626072, "Version", newJString(Version))
  result = call_21626071.call(nil, query_21626072, nil, nil, nil)

var getDefineIndexField* = Call_GetDefineIndexField_21626051(
    name: "getDefineIndexField", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineIndexField",
    validator: validate_GetDefineIndexField_21626052, base: "/",
    makeUrl: url_GetDefineIndexField_21626053,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDefineRankExpression_21626115 = ref object of OpenApiRestCall_21625435
proc url_PostDefineRankExpression_21626117(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDefineRankExpression_21626116(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626118 = query.getOrDefault("Action")
  valid_21626118 = validateParameter(valid_21626118, JString, required = true,
                                   default = newJString("DefineRankExpression"))
  if valid_21626118 != nil:
    section.add "Action", valid_21626118
  var valid_21626119 = query.getOrDefault("Version")
  valid_21626119 = validateParameter(valid_21626119, JString, required = true,
                                   default = newJString("2011-02-01"))
  if valid_21626119 != nil:
    section.add "Version", valid_21626119
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
  var valid_21626120 = header.getOrDefault("X-Amz-Date")
  valid_21626120 = validateParameter(valid_21626120, JString, required = false,
                                   default = nil)
  if valid_21626120 != nil:
    section.add "X-Amz-Date", valid_21626120
  var valid_21626121 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626121 = validateParameter(valid_21626121, JString, required = false,
                                   default = nil)
  if valid_21626121 != nil:
    section.add "X-Amz-Security-Token", valid_21626121
  var valid_21626122 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626122 = validateParameter(valid_21626122, JString, required = false,
                                   default = nil)
  if valid_21626122 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626122
  var valid_21626123 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626123 = validateParameter(valid_21626123, JString, required = false,
                                   default = nil)
  if valid_21626123 != nil:
    section.add "X-Amz-Algorithm", valid_21626123
  var valid_21626124 = header.getOrDefault("X-Amz-Signature")
  valid_21626124 = validateParameter(valid_21626124, JString, required = false,
                                   default = nil)
  if valid_21626124 != nil:
    section.add "X-Amz-Signature", valid_21626124
  var valid_21626125 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626125 = validateParameter(valid_21626125, JString, required = false,
                                   default = nil)
  if valid_21626125 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626125
  var valid_21626126 = header.getOrDefault("X-Amz-Credential")
  valid_21626126 = validateParameter(valid_21626126, JString, required = false,
                                   default = nil)
  if valid_21626126 != nil:
    section.add "X-Amz-Credential", valid_21626126
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
  var valid_21626127 = formData.getOrDefault("DomainName")
  valid_21626127 = validateParameter(valid_21626127, JString, required = true,
                                   default = nil)
  if valid_21626127 != nil:
    section.add "DomainName", valid_21626127
  var valid_21626128 = formData.getOrDefault("RankExpression.RankName")
  valid_21626128 = validateParameter(valid_21626128, JString, required = false,
                                   default = nil)
  if valid_21626128 != nil:
    section.add "RankExpression.RankName", valid_21626128
  var valid_21626129 = formData.getOrDefault("RankExpression.RankExpression")
  valid_21626129 = validateParameter(valid_21626129, JString, required = false,
                                   default = nil)
  if valid_21626129 != nil:
    section.add "RankExpression.RankExpression", valid_21626129
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626130: Call_PostDefineRankExpression_21626115;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Configures a <code>RankExpression</code> for the search domain. Used to create new rank expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. You can configure a maximum of 50 rank expressions.
  ## 
  let valid = call_21626130.validator(path, query, header, formData, body, _)
  let scheme = call_21626130.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626130.makeUrl(scheme.get, call_21626130.host, call_21626130.base,
                               call_21626130.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626130, uri, valid, _)

proc call*(call_21626131: Call_PostDefineRankExpression_21626115;
          DomainName: string; RankExpressionRankName: string = "";
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
  var query_21626132 = newJObject()
  var formData_21626133 = newJObject()
  add(formData_21626133, "DomainName", newJString(DomainName))
  add(formData_21626133, "RankExpression.RankName",
      newJString(RankExpressionRankName))
  add(formData_21626133, "RankExpression.RankExpression",
      newJString(RankExpressionRankExpression))
  add(query_21626132, "Action", newJString(Action))
  add(query_21626132, "Version", newJString(Version))
  result = call_21626131.call(nil, query_21626132, nil, formData_21626133, nil)

var postDefineRankExpression* = Call_PostDefineRankExpression_21626115(
    name: "postDefineRankExpression", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineRankExpression",
    validator: validate_PostDefineRankExpression_21626116, base: "/",
    makeUrl: url_PostDefineRankExpression_21626117,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDefineRankExpression_21626097 = ref object of OpenApiRestCall_21625435
proc url_GetDefineRankExpression_21626099(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDefineRankExpression_21626098(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626100 = query.getOrDefault("Action")
  valid_21626100 = validateParameter(valid_21626100, JString, required = true,
                                   default = newJString("DefineRankExpression"))
  if valid_21626100 != nil:
    section.add "Action", valid_21626100
  var valid_21626101 = query.getOrDefault("RankExpression.RankExpression")
  valid_21626101 = validateParameter(valid_21626101, JString, required = false,
                                   default = nil)
  if valid_21626101 != nil:
    section.add "RankExpression.RankExpression", valid_21626101
  var valid_21626102 = query.getOrDefault("RankExpression.RankName")
  valid_21626102 = validateParameter(valid_21626102, JString, required = false,
                                   default = nil)
  if valid_21626102 != nil:
    section.add "RankExpression.RankName", valid_21626102
  var valid_21626103 = query.getOrDefault("DomainName")
  valid_21626103 = validateParameter(valid_21626103, JString, required = true,
                                   default = nil)
  if valid_21626103 != nil:
    section.add "DomainName", valid_21626103
  var valid_21626104 = query.getOrDefault("Version")
  valid_21626104 = validateParameter(valid_21626104, JString, required = true,
                                   default = newJString("2011-02-01"))
  if valid_21626104 != nil:
    section.add "Version", valid_21626104
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
  var valid_21626105 = header.getOrDefault("X-Amz-Date")
  valid_21626105 = validateParameter(valid_21626105, JString, required = false,
                                   default = nil)
  if valid_21626105 != nil:
    section.add "X-Amz-Date", valid_21626105
  var valid_21626106 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626106 = validateParameter(valid_21626106, JString, required = false,
                                   default = nil)
  if valid_21626106 != nil:
    section.add "X-Amz-Security-Token", valid_21626106
  var valid_21626107 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626107 = validateParameter(valid_21626107, JString, required = false,
                                   default = nil)
  if valid_21626107 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626107
  var valid_21626108 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626108 = validateParameter(valid_21626108, JString, required = false,
                                   default = nil)
  if valid_21626108 != nil:
    section.add "X-Amz-Algorithm", valid_21626108
  var valid_21626109 = header.getOrDefault("X-Amz-Signature")
  valid_21626109 = validateParameter(valid_21626109, JString, required = false,
                                   default = nil)
  if valid_21626109 != nil:
    section.add "X-Amz-Signature", valid_21626109
  var valid_21626110 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626110 = validateParameter(valid_21626110, JString, required = false,
                                   default = nil)
  if valid_21626110 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626110
  var valid_21626111 = header.getOrDefault("X-Amz-Credential")
  valid_21626111 = validateParameter(valid_21626111, JString, required = false,
                                   default = nil)
  if valid_21626111 != nil:
    section.add "X-Amz-Credential", valid_21626111
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626112: Call_GetDefineRankExpression_21626097;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Configures a <code>RankExpression</code> for the search domain. Used to create new rank expressions and modify existing ones. If the expression exists, the new configuration replaces the old one. You can configure a maximum of 50 rank expressions.
  ## 
  let valid = call_21626112.validator(path, query, header, formData, body, _)
  let scheme = call_21626112.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626112.makeUrl(scheme.get, call_21626112.host, call_21626112.base,
                               call_21626112.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626112, uri, valid, _)

proc call*(call_21626113: Call_GetDefineRankExpression_21626097;
          DomainName: string; Action: string = "DefineRankExpression";
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
  var query_21626114 = newJObject()
  add(query_21626114, "Action", newJString(Action))
  add(query_21626114, "RankExpression.RankExpression",
      newJString(RankExpressionRankExpression))
  add(query_21626114, "RankExpression.RankName",
      newJString(RankExpressionRankName))
  add(query_21626114, "DomainName", newJString(DomainName))
  add(query_21626114, "Version", newJString(Version))
  result = call_21626113.call(nil, query_21626114, nil, nil, nil)

var getDefineRankExpression* = Call_GetDefineRankExpression_21626097(
    name: "getDefineRankExpression", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DefineRankExpression",
    validator: validate_GetDefineRankExpression_21626098, base: "/",
    makeUrl: url_GetDefineRankExpression_21626099,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteDomain_21626150 = ref object of OpenApiRestCall_21625435
proc url_PostDeleteDomain_21626152(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteDomain_21626151(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626153 = query.getOrDefault("Action")
  valid_21626153 = validateParameter(valid_21626153, JString, required = true,
                                   default = newJString("DeleteDomain"))
  if valid_21626153 != nil:
    section.add "Action", valid_21626153
  var valid_21626154 = query.getOrDefault("Version")
  valid_21626154 = validateParameter(valid_21626154, JString, required = true,
                                   default = newJString("2011-02-01"))
  if valid_21626154 != nil:
    section.add "Version", valid_21626154
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
  var valid_21626155 = header.getOrDefault("X-Amz-Date")
  valid_21626155 = validateParameter(valid_21626155, JString, required = false,
                                   default = nil)
  if valid_21626155 != nil:
    section.add "X-Amz-Date", valid_21626155
  var valid_21626156 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626156 = validateParameter(valid_21626156, JString, required = false,
                                   default = nil)
  if valid_21626156 != nil:
    section.add "X-Amz-Security-Token", valid_21626156
  var valid_21626157 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626157 = validateParameter(valid_21626157, JString, required = false,
                                   default = nil)
  if valid_21626157 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626157
  var valid_21626158 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626158 = validateParameter(valid_21626158, JString, required = false,
                                   default = nil)
  if valid_21626158 != nil:
    section.add "X-Amz-Algorithm", valid_21626158
  var valid_21626159 = header.getOrDefault("X-Amz-Signature")
  valid_21626159 = validateParameter(valid_21626159, JString, required = false,
                                   default = nil)
  if valid_21626159 != nil:
    section.add "X-Amz-Signature", valid_21626159
  var valid_21626160 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626160 = validateParameter(valid_21626160, JString, required = false,
                                   default = nil)
  if valid_21626160 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626160
  var valid_21626161 = header.getOrDefault("X-Amz-Credential")
  valid_21626161 = validateParameter(valid_21626161, JString, required = false,
                                   default = nil)
  if valid_21626161 != nil:
    section.add "X-Amz-Credential", valid_21626161
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_21626162 = formData.getOrDefault("DomainName")
  valid_21626162 = validateParameter(valid_21626162, JString, required = true,
                                   default = nil)
  if valid_21626162 != nil:
    section.add "DomainName", valid_21626162
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626163: Call_PostDeleteDomain_21626150; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Permanently deletes a search domain and all of its data.
  ## 
  let valid = call_21626163.validator(path, query, header, formData, body, _)
  let scheme = call_21626163.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626163.makeUrl(scheme.get, call_21626163.host, call_21626163.base,
                               call_21626163.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626163, uri, valid, _)

proc call*(call_21626164: Call_PostDeleteDomain_21626150; DomainName: string;
          Action: string = "DeleteDomain"; Version: string = "2011-02-01"): Recallable =
  ## postDeleteDomain
  ## Permanently deletes a search domain and all of its data.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626165 = newJObject()
  var formData_21626166 = newJObject()
  add(formData_21626166, "DomainName", newJString(DomainName))
  add(query_21626165, "Action", newJString(Action))
  add(query_21626165, "Version", newJString(Version))
  result = call_21626164.call(nil, query_21626165, nil, formData_21626166, nil)

var postDeleteDomain* = Call_PostDeleteDomain_21626150(name: "postDeleteDomain",
    meth: HttpMethod.HttpPost, host: "cloudsearch.amazonaws.com",
    route: "/#Action=DeleteDomain", validator: validate_PostDeleteDomain_21626151,
    base: "/", makeUrl: url_PostDeleteDomain_21626152,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteDomain_21626134 = ref object of OpenApiRestCall_21625435
proc url_GetDeleteDomain_21626136(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteDomain_21626135(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626137 = query.getOrDefault("Action")
  valid_21626137 = validateParameter(valid_21626137, JString, required = true,
                                   default = newJString("DeleteDomain"))
  if valid_21626137 != nil:
    section.add "Action", valid_21626137
  var valid_21626138 = query.getOrDefault("DomainName")
  valid_21626138 = validateParameter(valid_21626138, JString, required = true,
                                   default = nil)
  if valid_21626138 != nil:
    section.add "DomainName", valid_21626138
  var valid_21626139 = query.getOrDefault("Version")
  valid_21626139 = validateParameter(valid_21626139, JString, required = true,
                                   default = newJString("2011-02-01"))
  if valid_21626139 != nil:
    section.add "Version", valid_21626139
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
  var valid_21626140 = header.getOrDefault("X-Amz-Date")
  valid_21626140 = validateParameter(valid_21626140, JString, required = false,
                                   default = nil)
  if valid_21626140 != nil:
    section.add "X-Amz-Date", valid_21626140
  var valid_21626141 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626141 = validateParameter(valid_21626141, JString, required = false,
                                   default = nil)
  if valid_21626141 != nil:
    section.add "X-Amz-Security-Token", valid_21626141
  var valid_21626142 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626142 = validateParameter(valid_21626142, JString, required = false,
                                   default = nil)
  if valid_21626142 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626142
  var valid_21626143 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626143 = validateParameter(valid_21626143, JString, required = false,
                                   default = nil)
  if valid_21626143 != nil:
    section.add "X-Amz-Algorithm", valid_21626143
  var valid_21626144 = header.getOrDefault("X-Amz-Signature")
  valid_21626144 = validateParameter(valid_21626144, JString, required = false,
                                   default = nil)
  if valid_21626144 != nil:
    section.add "X-Amz-Signature", valid_21626144
  var valid_21626145 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626145 = validateParameter(valid_21626145, JString, required = false,
                                   default = nil)
  if valid_21626145 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626145
  var valid_21626146 = header.getOrDefault("X-Amz-Credential")
  valid_21626146 = validateParameter(valid_21626146, JString, required = false,
                                   default = nil)
  if valid_21626146 != nil:
    section.add "X-Amz-Credential", valid_21626146
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626147: Call_GetDeleteDomain_21626134; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Permanently deletes a search domain and all of its data.
  ## 
  let valid = call_21626147.validator(path, query, header, formData, body, _)
  let scheme = call_21626147.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626147.makeUrl(scheme.get, call_21626147.host, call_21626147.base,
                               call_21626147.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626147, uri, valid, _)

proc call*(call_21626148: Call_GetDeleteDomain_21626134; DomainName: string;
          Action: string = "DeleteDomain"; Version: string = "2011-02-01"): Recallable =
  ## getDeleteDomain
  ## Permanently deletes a search domain and all of its data.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_21626149 = newJObject()
  add(query_21626149, "Action", newJString(Action))
  add(query_21626149, "DomainName", newJString(DomainName))
  add(query_21626149, "Version", newJString(Version))
  result = call_21626148.call(nil, query_21626149, nil, nil, nil)

var getDeleteDomain* = Call_GetDeleteDomain_21626134(name: "getDeleteDomain",
    meth: HttpMethod.HttpGet, host: "cloudsearch.amazonaws.com",
    route: "/#Action=DeleteDomain", validator: validate_GetDeleteDomain_21626135,
    base: "/", makeUrl: url_GetDeleteDomain_21626136,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteIndexField_21626184 = ref object of OpenApiRestCall_21625435
proc url_PostDeleteIndexField_21626186(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteIndexField_21626185(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626187 = query.getOrDefault("Action")
  valid_21626187 = validateParameter(valid_21626187, JString, required = true,
                                   default = newJString("DeleteIndexField"))
  if valid_21626187 != nil:
    section.add "Action", valid_21626187
  var valid_21626188 = query.getOrDefault("Version")
  valid_21626188 = validateParameter(valid_21626188, JString, required = true,
                                   default = newJString("2011-02-01"))
  if valid_21626188 != nil:
    section.add "Version", valid_21626188
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
  var valid_21626189 = header.getOrDefault("X-Amz-Date")
  valid_21626189 = validateParameter(valid_21626189, JString, required = false,
                                   default = nil)
  if valid_21626189 != nil:
    section.add "X-Amz-Date", valid_21626189
  var valid_21626190 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626190 = validateParameter(valid_21626190, JString, required = false,
                                   default = nil)
  if valid_21626190 != nil:
    section.add "X-Amz-Security-Token", valid_21626190
  var valid_21626191 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626191 = validateParameter(valid_21626191, JString, required = false,
                                   default = nil)
  if valid_21626191 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626191
  var valid_21626192 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626192 = validateParameter(valid_21626192, JString, required = false,
                                   default = nil)
  if valid_21626192 != nil:
    section.add "X-Amz-Algorithm", valid_21626192
  var valid_21626193 = header.getOrDefault("X-Amz-Signature")
  valid_21626193 = validateParameter(valid_21626193, JString, required = false,
                                   default = nil)
  if valid_21626193 != nil:
    section.add "X-Amz-Signature", valid_21626193
  var valid_21626194 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626194 = validateParameter(valid_21626194, JString, required = false,
                                   default = nil)
  if valid_21626194 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626194
  var valid_21626195 = header.getOrDefault("X-Amz-Credential")
  valid_21626195 = validateParameter(valid_21626195, JString, required = false,
                                   default = nil)
  if valid_21626195 != nil:
    section.add "X-Amz-Credential", valid_21626195
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   IndexFieldName: JString (required)
  ##                 : A string that represents the name of an index field. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_21626196 = formData.getOrDefault("DomainName")
  valid_21626196 = validateParameter(valid_21626196, JString, required = true,
                                   default = nil)
  if valid_21626196 != nil:
    section.add "DomainName", valid_21626196
  var valid_21626197 = formData.getOrDefault("IndexFieldName")
  valid_21626197 = validateParameter(valid_21626197, JString, required = true,
                                   default = nil)
  if valid_21626197 != nil:
    section.add "IndexFieldName", valid_21626197
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626198: Call_PostDeleteIndexField_21626184; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes an <code>IndexField</code> from the search domain.
  ## 
  let valid = call_21626198.validator(path, query, header, formData, body, _)
  let scheme = call_21626198.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626198.makeUrl(scheme.get, call_21626198.host, call_21626198.base,
                               call_21626198.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626198, uri, valid, _)

proc call*(call_21626199: Call_PostDeleteIndexField_21626184; DomainName: string;
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
  var query_21626200 = newJObject()
  var formData_21626201 = newJObject()
  add(formData_21626201, "DomainName", newJString(DomainName))
  add(formData_21626201, "IndexFieldName", newJString(IndexFieldName))
  add(query_21626200, "Action", newJString(Action))
  add(query_21626200, "Version", newJString(Version))
  result = call_21626199.call(nil, query_21626200, nil, formData_21626201, nil)

var postDeleteIndexField* = Call_PostDeleteIndexField_21626184(
    name: "postDeleteIndexField", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteIndexField",
    validator: validate_PostDeleteIndexField_21626185, base: "/",
    makeUrl: url_PostDeleteIndexField_21626186,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteIndexField_21626167 = ref object of OpenApiRestCall_21625435
proc url_GetDeleteIndexField_21626169(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteIndexField_21626168(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626170 = query.getOrDefault("IndexFieldName")
  valid_21626170 = validateParameter(valid_21626170, JString, required = true,
                                   default = nil)
  if valid_21626170 != nil:
    section.add "IndexFieldName", valid_21626170
  var valid_21626171 = query.getOrDefault("Action")
  valid_21626171 = validateParameter(valid_21626171, JString, required = true,
                                   default = newJString("DeleteIndexField"))
  if valid_21626171 != nil:
    section.add "Action", valid_21626171
  var valid_21626172 = query.getOrDefault("DomainName")
  valid_21626172 = validateParameter(valid_21626172, JString, required = true,
                                   default = nil)
  if valid_21626172 != nil:
    section.add "DomainName", valid_21626172
  var valid_21626173 = query.getOrDefault("Version")
  valid_21626173 = validateParameter(valid_21626173, JString, required = true,
                                   default = newJString("2011-02-01"))
  if valid_21626173 != nil:
    section.add "Version", valid_21626173
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
  var valid_21626174 = header.getOrDefault("X-Amz-Date")
  valid_21626174 = validateParameter(valid_21626174, JString, required = false,
                                   default = nil)
  if valid_21626174 != nil:
    section.add "X-Amz-Date", valid_21626174
  var valid_21626175 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626175 = validateParameter(valid_21626175, JString, required = false,
                                   default = nil)
  if valid_21626175 != nil:
    section.add "X-Amz-Security-Token", valid_21626175
  var valid_21626176 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626176 = validateParameter(valid_21626176, JString, required = false,
                                   default = nil)
  if valid_21626176 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626176
  var valid_21626177 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626177 = validateParameter(valid_21626177, JString, required = false,
                                   default = nil)
  if valid_21626177 != nil:
    section.add "X-Amz-Algorithm", valid_21626177
  var valid_21626178 = header.getOrDefault("X-Amz-Signature")
  valid_21626178 = validateParameter(valid_21626178, JString, required = false,
                                   default = nil)
  if valid_21626178 != nil:
    section.add "X-Amz-Signature", valid_21626178
  var valid_21626179 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626179 = validateParameter(valid_21626179, JString, required = false,
                                   default = nil)
  if valid_21626179 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626179
  var valid_21626180 = header.getOrDefault("X-Amz-Credential")
  valid_21626180 = validateParameter(valid_21626180, JString, required = false,
                                   default = nil)
  if valid_21626180 != nil:
    section.add "X-Amz-Credential", valid_21626180
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626181: Call_GetDeleteIndexField_21626167; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes an <code>IndexField</code> from the search domain.
  ## 
  let valid = call_21626181.validator(path, query, header, formData, body, _)
  let scheme = call_21626181.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626181.makeUrl(scheme.get, call_21626181.host, call_21626181.base,
                               call_21626181.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626181, uri, valid, _)

proc call*(call_21626182: Call_GetDeleteIndexField_21626167;
          IndexFieldName: string; DomainName: string;
          Action: string = "DeleteIndexField"; Version: string = "2011-02-01"): Recallable =
  ## getDeleteIndexField
  ## Removes an <code>IndexField</code> from the search domain.
  ##   IndexFieldName: string (required)
  ##                 : A string that represents the name of an index field. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_21626183 = newJObject()
  add(query_21626183, "IndexFieldName", newJString(IndexFieldName))
  add(query_21626183, "Action", newJString(Action))
  add(query_21626183, "DomainName", newJString(DomainName))
  add(query_21626183, "Version", newJString(Version))
  result = call_21626182.call(nil, query_21626183, nil, nil, nil)

var getDeleteIndexField* = Call_GetDeleteIndexField_21626167(
    name: "getDeleteIndexField", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteIndexField",
    validator: validate_GetDeleteIndexField_21626168, base: "/",
    makeUrl: url_GetDeleteIndexField_21626169,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDeleteRankExpression_21626219 = ref object of OpenApiRestCall_21625435
proc url_PostDeleteRankExpression_21626221(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDeleteRankExpression_21626220(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626222 = query.getOrDefault("Action")
  valid_21626222 = validateParameter(valid_21626222, JString, required = true,
                                   default = newJString("DeleteRankExpression"))
  if valid_21626222 != nil:
    section.add "Action", valid_21626222
  var valid_21626223 = query.getOrDefault("Version")
  valid_21626223 = validateParameter(valid_21626223, JString, required = true,
                                   default = newJString("2011-02-01"))
  if valid_21626223 != nil:
    section.add "Version", valid_21626223
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
  var valid_21626224 = header.getOrDefault("X-Amz-Date")
  valid_21626224 = validateParameter(valid_21626224, JString, required = false,
                                   default = nil)
  if valid_21626224 != nil:
    section.add "X-Amz-Date", valid_21626224
  var valid_21626225 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626225 = validateParameter(valid_21626225, JString, required = false,
                                   default = nil)
  if valid_21626225 != nil:
    section.add "X-Amz-Security-Token", valid_21626225
  var valid_21626226 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626226 = validateParameter(valid_21626226, JString, required = false,
                                   default = nil)
  if valid_21626226 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626226
  var valid_21626227 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626227 = validateParameter(valid_21626227, JString, required = false,
                                   default = nil)
  if valid_21626227 != nil:
    section.add "X-Amz-Algorithm", valid_21626227
  var valid_21626228 = header.getOrDefault("X-Amz-Signature")
  valid_21626228 = validateParameter(valid_21626228, JString, required = false,
                                   default = nil)
  if valid_21626228 != nil:
    section.add "X-Amz-Signature", valid_21626228
  var valid_21626229 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626229 = validateParameter(valid_21626229, JString, required = false,
                                   default = nil)
  if valid_21626229 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626229
  var valid_21626230 = header.getOrDefault("X-Amz-Credential")
  valid_21626230 = validateParameter(valid_21626230, JString, required = false,
                                   default = nil)
  if valid_21626230 != nil:
    section.add "X-Amz-Credential", valid_21626230
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   RankName: JString (required)
  ##           : A string that represents the name of an index field. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_21626231 = formData.getOrDefault("DomainName")
  valid_21626231 = validateParameter(valid_21626231, JString, required = true,
                                   default = nil)
  if valid_21626231 != nil:
    section.add "DomainName", valid_21626231
  var valid_21626232 = formData.getOrDefault("RankName")
  valid_21626232 = validateParameter(valid_21626232, JString, required = true,
                                   default = nil)
  if valid_21626232 != nil:
    section.add "RankName", valid_21626232
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626233: Call_PostDeleteRankExpression_21626219;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes a <code>RankExpression</code> from the search domain.
  ## 
  let valid = call_21626233.validator(path, query, header, formData, body, _)
  let scheme = call_21626233.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626233.makeUrl(scheme.get, call_21626233.host, call_21626233.base,
                               call_21626233.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626233, uri, valid, _)

proc call*(call_21626234: Call_PostDeleteRankExpression_21626219;
          DomainName: string; RankName: string;
          Action: string = "DeleteRankExpression"; Version: string = "2011-02-01"): Recallable =
  ## postDeleteRankExpression
  ## Removes a <code>RankExpression</code> from the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   RankName: string (required)
  ##           : A string that represents the name of an index field. Field names must begin with a letter and can contain the following characters: a-z (lowercase), 0-9, and _ (underscore). Uppercase letters and hyphens are not allowed. The names "body", "docid", and "text_relevance" are reserved and cannot be specified as field or rank expression names.
  ##   Version: string (required)
  var query_21626235 = newJObject()
  var formData_21626236 = newJObject()
  add(formData_21626236, "DomainName", newJString(DomainName))
  add(query_21626235, "Action", newJString(Action))
  add(formData_21626236, "RankName", newJString(RankName))
  add(query_21626235, "Version", newJString(Version))
  result = call_21626234.call(nil, query_21626235, nil, formData_21626236, nil)

var postDeleteRankExpression* = Call_PostDeleteRankExpression_21626219(
    name: "postDeleteRankExpression", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteRankExpression",
    validator: validate_PostDeleteRankExpression_21626220, base: "/",
    makeUrl: url_PostDeleteRankExpression_21626221,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeleteRankExpression_21626202 = ref object of OpenApiRestCall_21625435
proc url_GetDeleteRankExpression_21626204(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeleteRankExpression_21626203(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626205 = query.getOrDefault("RankName")
  valid_21626205 = validateParameter(valid_21626205, JString, required = true,
                                   default = nil)
  if valid_21626205 != nil:
    section.add "RankName", valid_21626205
  var valid_21626206 = query.getOrDefault("Action")
  valid_21626206 = validateParameter(valid_21626206, JString, required = true,
                                   default = newJString("DeleteRankExpression"))
  if valid_21626206 != nil:
    section.add "Action", valid_21626206
  var valid_21626207 = query.getOrDefault("DomainName")
  valid_21626207 = validateParameter(valid_21626207, JString, required = true,
                                   default = nil)
  if valid_21626207 != nil:
    section.add "DomainName", valid_21626207
  var valid_21626208 = query.getOrDefault("Version")
  valid_21626208 = validateParameter(valid_21626208, JString, required = true,
                                   default = newJString("2011-02-01"))
  if valid_21626208 != nil:
    section.add "Version", valid_21626208
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
  var valid_21626209 = header.getOrDefault("X-Amz-Date")
  valid_21626209 = validateParameter(valid_21626209, JString, required = false,
                                   default = nil)
  if valid_21626209 != nil:
    section.add "X-Amz-Date", valid_21626209
  var valid_21626210 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626210 = validateParameter(valid_21626210, JString, required = false,
                                   default = nil)
  if valid_21626210 != nil:
    section.add "X-Amz-Security-Token", valid_21626210
  var valid_21626211 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626211 = validateParameter(valid_21626211, JString, required = false,
                                   default = nil)
  if valid_21626211 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626211
  var valid_21626212 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626212 = validateParameter(valid_21626212, JString, required = false,
                                   default = nil)
  if valid_21626212 != nil:
    section.add "X-Amz-Algorithm", valid_21626212
  var valid_21626213 = header.getOrDefault("X-Amz-Signature")
  valid_21626213 = validateParameter(valid_21626213, JString, required = false,
                                   default = nil)
  if valid_21626213 != nil:
    section.add "X-Amz-Signature", valid_21626213
  var valid_21626214 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626214 = validateParameter(valid_21626214, JString, required = false,
                                   default = nil)
  if valid_21626214 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626214
  var valid_21626215 = header.getOrDefault("X-Amz-Credential")
  valid_21626215 = validateParameter(valid_21626215, JString, required = false,
                                   default = nil)
  if valid_21626215 != nil:
    section.add "X-Amz-Credential", valid_21626215
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626216: Call_GetDeleteRankExpression_21626202;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes a <code>RankExpression</code> from the search domain.
  ## 
  let valid = call_21626216.validator(path, query, header, formData, body, _)
  let scheme = call_21626216.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626216.makeUrl(scheme.get, call_21626216.host, call_21626216.base,
                               call_21626216.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626216, uri, valid, _)

proc call*(call_21626217: Call_GetDeleteRankExpression_21626202; RankName: string;
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
  var query_21626218 = newJObject()
  add(query_21626218, "RankName", newJString(RankName))
  add(query_21626218, "Action", newJString(Action))
  add(query_21626218, "DomainName", newJString(DomainName))
  add(query_21626218, "Version", newJString(Version))
  result = call_21626217.call(nil, query_21626218, nil, nil, nil)

var getDeleteRankExpression* = Call_GetDeleteRankExpression_21626202(
    name: "getDeleteRankExpression", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DeleteRankExpression",
    validator: validate_GetDeleteRankExpression_21626203, base: "/",
    makeUrl: url_GetDeleteRankExpression_21626204,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeAvailabilityOptions_21626253 = ref object of OpenApiRestCall_21625435
proc url_PostDescribeAvailabilityOptions_21626255(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeAvailabilityOptions_21626254(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626256 = query.getOrDefault("Action")
  valid_21626256 = validateParameter(valid_21626256, JString, required = true, default = newJString(
      "DescribeAvailabilityOptions"))
  if valid_21626256 != nil:
    section.add "Action", valid_21626256
  var valid_21626257 = query.getOrDefault("Version")
  valid_21626257 = validateParameter(valid_21626257, JString, required = true,
                                   default = newJString("2011-02-01"))
  if valid_21626257 != nil:
    section.add "Version", valid_21626257
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
  var valid_21626258 = header.getOrDefault("X-Amz-Date")
  valid_21626258 = validateParameter(valid_21626258, JString, required = false,
                                   default = nil)
  if valid_21626258 != nil:
    section.add "X-Amz-Date", valid_21626258
  var valid_21626259 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626259 = validateParameter(valid_21626259, JString, required = false,
                                   default = nil)
  if valid_21626259 != nil:
    section.add "X-Amz-Security-Token", valid_21626259
  var valid_21626260 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626260 = validateParameter(valid_21626260, JString, required = false,
                                   default = nil)
  if valid_21626260 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626260
  var valid_21626261 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626261 = validateParameter(valid_21626261, JString, required = false,
                                   default = nil)
  if valid_21626261 != nil:
    section.add "X-Amz-Algorithm", valid_21626261
  var valid_21626262 = header.getOrDefault("X-Amz-Signature")
  valid_21626262 = validateParameter(valid_21626262, JString, required = false,
                                   default = nil)
  if valid_21626262 != nil:
    section.add "X-Amz-Signature", valid_21626262
  var valid_21626263 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626263 = validateParameter(valid_21626263, JString, required = false,
                                   default = nil)
  if valid_21626263 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626263
  var valid_21626264 = header.getOrDefault("X-Amz-Credential")
  valid_21626264 = validateParameter(valid_21626264, JString, required = false,
                                   default = nil)
  if valid_21626264 != nil:
    section.add "X-Amz-Credential", valid_21626264
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_21626265 = formData.getOrDefault("DomainName")
  valid_21626265 = validateParameter(valid_21626265, JString, required = true,
                                   default = nil)
  if valid_21626265 != nil:
    section.add "DomainName", valid_21626265
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626266: Call_PostDescribeAvailabilityOptions_21626253;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_21626266.validator(path, query, header, formData, body, _)
  let scheme = call_21626266.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626266.makeUrl(scheme.get, call_21626266.host, call_21626266.base,
                               call_21626266.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626266, uri, valid, _)

proc call*(call_21626267: Call_PostDescribeAvailabilityOptions_21626253;
          DomainName: string; Action: string = "DescribeAvailabilityOptions";
          Version: string = "2011-02-01"): Recallable =
  ## postDescribeAvailabilityOptions
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626268 = newJObject()
  var formData_21626269 = newJObject()
  add(formData_21626269, "DomainName", newJString(DomainName))
  add(query_21626268, "Action", newJString(Action))
  add(query_21626268, "Version", newJString(Version))
  result = call_21626267.call(nil, query_21626268, nil, formData_21626269, nil)

var postDescribeAvailabilityOptions* = Call_PostDescribeAvailabilityOptions_21626253(
    name: "postDescribeAvailabilityOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeAvailabilityOptions",
    validator: validate_PostDescribeAvailabilityOptions_21626254, base: "/",
    makeUrl: url_PostDescribeAvailabilityOptions_21626255,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeAvailabilityOptions_21626237 = ref object of OpenApiRestCall_21625435
proc url_GetDescribeAvailabilityOptions_21626239(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeAvailabilityOptions_21626238(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626240 = query.getOrDefault("Action")
  valid_21626240 = validateParameter(valid_21626240, JString, required = true, default = newJString(
      "DescribeAvailabilityOptions"))
  if valid_21626240 != nil:
    section.add "Action", valid_21626240
  var valid_21626241 = query.getOrDefault("DomainName")
  valid_21626241 = validateParameter(valid_21626241, JString, required = true,
                                   default = nil)
  if valid_21626241 != nil:
    section.add "DomainName", valid_21626241
  var valid_21626242 = query.getOrDefault("Version")
  valid_21626242 = validateParameter(valid_21626242, JString, required = true,
                                   default = newJString("2011-02-01"))
  if valid_21626242 != nil:
    section.add "Version", valid_21626242
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
  var valid_21626243 = header.getOrDefault("X-Amz-Date")
  valid_21626243 = validateParameter(valid_21626243, JString, required = false,
                                   default = nil)
  if valid_21626243 != nil:
    section.add "X-Amz-Date", valid_21626243
  var valid_21626244 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626244 = validateParameter(valid_21626244, JString, required = false,
                                   default = nil)
  if valid_21626244 != nil:
    section.add "X-Amz-Security-Token", valid_21626244
  var valid_21626245 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626245 = validateParameter(valid_21626245, JString, required = false,
                                   default = nil)
  if valid_21626245 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626245
  var valid_21626246 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626246 = validateParameter(valid_21626246, JString, required = false,
                                   default = nil)
  if valid_21626246 != nil:
    section.add "X-Amz-Algorithm", valid_21626246
  var valid_21626247 = header.getOrDefault("X-Amz-Signature")
  valid_21626247 = validateParameter(valid_21626247, JString, required = false,
                                   default = nil)
  if valid_21626247 != nil:
    section.add "X-Amz-Signature", valid_21626247
  var valid_21626248 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626248 = validateParameter(valid_21626248, JString, required = false,
                                   default = nil)
  if valid_21626248 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626248
  var valid_21626249 = header.getOrDefault("X-Amz-Credential")
  valid_21626249 = validateParameter(valid_21626249, JString, required = false,
                                   default = nil)
  if valid_21626249 != nil:
    section.add "X-Amz-Credential", valid_21626249
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626250: Call_GetDescribeAvailabilityOptions_21626237;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_21626250.validator(path, query, header, formData, body, _)
  let scheme = call_21626250.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626250.makeUrl(scheme.get, call_21626250.host, call_21626250.base,
                               call_21626250.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626250, uri, valid, _)

proc call*(call_21626251: Call_GetDescribeAvailabilityOptions_21626237;
          DomainName: string; Action: string = "DescribeAvailabilityOptions";
          Version: string = "2011-02-01"): Recallable =
  ## getDescribeAvailabilityOptions
  ## Gets the availability options configured for a domain. By default, shows the configuration with any pending changes. Set the <code>Deployed</code> option to <code>true</code> to show the active configuration and exclude pending changes. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_21626252 = newJObject()
  add(query_21626252, "Action", newJString(Action))
  add(query_21626252, "DomainName", newJString(DomainName))
  add(query_21626252, "Version", newJString(Version))
  result = call_21626251.call(nil, query_21626252, nil, nil, nil)

var getDescribeAvailabilityOptions* = Call_GetDescribeAvailabilityOptions_21626237(
    name: "getDescribeAvailabilityOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeAvailabilityOptions",
    validator: validate_GetDescribeAvailabilityOptions_21626238, base: "/",
    makeUrl: url_GetDescribeAvailabilityOptions_21626239,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDefaultSearchField_21626286 = ref object of OpenApiRestCall_21625435
proc url_PostDescribeDefaultSearchField_21626288(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDefaultSearchField_21626287(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626289 = query.getOrDefault("Action")
  valid_21626289 = validateParameter(valid_21626289, JString, required = true, default = newJString(
      "DescribeDefaultSearchField"))
  if valid_21626289 != nil:
    section.add "Action", valid_21626289
  var valid_21626290 = query.getOrDefault("Version")
  valid_21626290 = validateParameter(valid_21626290, JString, required = true,
                                   default = newJString("2011-02-01"))
  if valid_21626290 != nil:
    section.add "Version", valid_21626290
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
  var valid_21626291 = header.getOrDefault("X-Amz-Date")
  valid_21626291 = validateParameter(valid_21626291, JString, required = false,
                                   default = nil)
  if valid_21626291 != nil:
    section.add "X-Amz-Date", valid_21626291
  var valid_21626292 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626292 = validateParameter(valid_21626292, JString, required = false,
                                   default = nil)
  if valid_21626292 != nil:
    section.add "X-Amz-Security-Token", valid_21626292
  var valid_21626293 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626293 = validateParameter(valid_21626293, JString, required = false,
                                   default = nil)
  if valid_21626293 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626293
  var valid_21626294 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626294 = validateParameter(valid_21626294, JString, required = false,
                                   default = nil)
  if valid_21626294 != nil:
    section.add "X-Amz-Algorithm", valid_21626294
  var valid_21626295 = header.getOrDefault("X-Amz-Signature")
  valid_21626295 = validateParameter(valid_21626295, JString, required = false,
                                   default = nil)
  if valid_21626295 != nil:
    section.add "X-Amz-Signature", valid_21626295
  var valid_21626296 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626296 = validateParameter(valid_21626296, JString, required = false,
                                   default = nil)
  if valid_21626296 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626296
  var valid_21626297 = header.getOrDefault("X-Amz-Credential")
  valid_21626297 = validateParameter(valid_21626297, JString, required = false,
                                   default = nil)
  if valid_21626297 != nil:
    section.add "X-Amz-Credential", valid_21626297
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_21626298 = formData.getOrDefault("DomainName")
  valid_21626298 = validateParameter(valid_21626298, JString, required = true,
                                   default = nil)
  if valid_21626298 != nil:
    section.add "DomainName", valid_21626298
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626299: Call_PostDescribeDefaultSearchField_21626286;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the default search field configured for the search domain.
  ## 
  let valid = call_21626299.validator(path, query, header, formData, body, _)
  let scheme = call_21626299.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626299.makeUrl(scheme.get, call_21626299.host, call_21626299.base,
                               call_21626299.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626299, uri, valid, _)

proc call*(call_21626300: Call_PostDescribeDefaultSearchField_21626286;
          DomainName: string; Action: string = "DescribeDefaultSearchField";
          Version: string = "2011-02-01"): Recallable =
  ## postDescribeDefaultSearchField
  ## Gets the default search field configured for the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626301 = newJObject()
  var formData_21626302 = newJObject()
  add(formData_21626302, "DomainName", newJString(DomainName))
  add(query_21626301, "Action", newJString(Action))
  add(query_21626301, "Version", newJString(Version))
  result = call_21626300.call(nil, query_21626301, nil, formData_21626302, nil)

var postDescribeDefaultSearchField* = Call_PostDescribeDefaultSearchField_21626286(
    name: "postDescribeDefaultSearchField", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeDefaultSearchField",
    validator: validate_PostDescribeDefaultSearchField_21626287, base: "/",
    makeUrl: url_PostDescribeDefaultSearchField_21626288,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDefaultSearchField_21626270 = ref object of OpenApiRestCall_21625435
proc url_GetDescribeDefaultSearchField_21626272(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDefaultSearchField_21626271(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626273 = query.getOrDefault("Action")
  valid_21626273 = validateParameter(valid_21626273, JString, required = true, default = newJString(
      "DescribeDefaultSearchField"))
  if valid_21626273 != nil:
    section.add "Action", valid_21626273
  var valid_21626274 = query.getOrDefault("DomainName")
  valid_21626274 = validateParameter(valid_21626274, JString, required = true,
                                   default = nil)
  if valid_21626274 != nil:
    section.add "DomainName", valid_21626274
  var valid_21626275 = query.getOrDefault("Version")
  valid_21626275 = validateParameter(valid_21626275, JString, required = true,
                                   default = newJString("2011-02-01"))
  if valid_21626275 != nil:
    section.add "Version", valid_21626275
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
  var valid_21626276 = header.getOrDefault("X-Amz-Date")
  valid_21626276 = validateParameter(valid_21626276, JString, required = false,
                                   default = nil)
  if valid_21626276 != nil:
    section.add "X-Amz-Date", valid_21626276
  var valid_21626277 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626277 = validateParameter(valid_21626277, JString, required = false,
                                   default = nil)
  if valid_21626277 != nil:
    section.add "X-Amz-Security-Token", valid_21626277
  var valid_21626278 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626278 = validateParameter(valid_21626278, JString, required = false,
                                   default = nil)
  if valid_21626278 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626278
  var valid_21626279 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626279 = validateParameter(valid_21626279, JString, required = false,
                                   default = nil)
  if valid_21626279 != nil:
    section.add "X-Amz-Algorithm", valid_21626279
  var valid_21626280 = header.getOrDefault("X-Amz-Signature")
  valid_21626280 = validateParameter(valid_21626280, JString, required = false,
                                   default = nil)
  if valid_21626280 != nil:
    section.add "X-Amz-Signature", valid_21626280
  var valid_21626281 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626281 = validateParameter(valid_21626281, JString, required = false,
                                   default = nil)
  if valid_21626281 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626281
  var valid_21626282 = header.getOrDefault("X-Amz-Credential")
  valid_21626282 = validateParameter(valid_21626282, JString, required = false,
                                   default = nil)
  if valid_21626282 != nil:
    section.add "X-Amz-Credential", valid_21626282
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626283: Call_GetDescribeDefaultSearchField_21626270;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the default search field configured for the search domain.
  ## 
  let valid = call_21626283.validator(path, query, header, formData, body, _)
  let scheme = call_21626283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626283.makeUrl(scheme.get, call_21626283.host, call_21626283.base,
                               call_21626283.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626283, uri, valid, _)

proc call*(call_21626284: Call_GetDescribeDefaultSearchField_21626270;
          DomainName: string; Action: string = "DescribeDefaultSearchField";
          Version: string = "2011-02-01"): Recallable =
  ## getDescribeDefaultSearchField
  ## Gets the default search field configured for the search domain.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_21626285 = newJObject()
  add(query_21626285, "Action", newJString(Action))
  add(query_21626285, "DomainName", newJString(DomainName))
  add(query_21626285, "Version", newJString(Version))
  result = call_21626284.call(nil, query_21626285, nil, nil, nil)

var getDescribeDefaultSearchField* = Call_GetDescribeDefaultSearchField_21626270(
    name: "getDescribeDefaultSearchField", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeDefaultSearchField",
    validator: validate_GetDescribeDefaultSearchField_21626271, base: "/",
    makeUrl: url_GetDescribeDefaultSearchField_21626272,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeDomains_21626319 = ref object of OpenApiRestCall_21625435
proc url_PostDescribeDomains_21626321(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeDomains_21626320(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626322 = query.getOrDefault("Action")
  valid_21626322 = validateParameter(valid_21626322, JString, required = true,
                                   default = newJString("DescribeDomains"))
  if valid_21626322 != nil:
    section.add "Action", valid_21626322
  var valid_21626323 = query.getOrDefault("Version")
  valid_21626323 = validateParameter(valid_21626323, JString, required = true,
                                   default = newJString("2011-02-01"))
  if valid_21626323 != nil:
    section.add "Version", valid_21626323
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
  var valid_21626324 = header.getOrDefault("X-Amz-Date")
  valid_21626324 = validateParameter(valid_21626324, JString, required = false,
                                   default = nil)
  if valid_21626324 != nil:
    section.add "X-Amz-Date", valid_21626324
  var valid_21626325 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626325 = validateParameter(valid_21626325, JString, required = false,
                                   default = nil)
  if valid_21626325 != nil:
    section.add "X-Amz-Security-Token", valid_21626325
  var valid_21626326 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626326 = validateParameter(valid_21626326, JString, required = false,
                                   default = nil)
  if valid_21626326 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626326
  var valid_21626327 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626327 = validateParameter(valid_21626327, JString, required = false,
                                   default = nil)
  if valid_21626327 != nil:
    section.add "X-Amz-Algorithm", valid_21626327
  var valid_21626328 = header.getOrDefault("X-Amz-Signature")
  valid_21626328 = validateParameter(valid_21626328, JString, required = false,
                                   default = nil)
  if valid_21626328 != nil:
    section.add "X-Amz-Signature", valid_21626328
  var valid_21626329 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626329 = validateParameter(valid_21626329, JString, required = false,
                                   default = nil)
  if valid_21626329 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626329
  var valid_21626330 = header.getOrDefault("X-Amz-Credential")
  valid_21626330 = validateParameter(valid_21626330, JString, required = false,
                                   default = nil)
  if valid_21626330 != nil:
    section.add "X-Amz-Credential", valid_21626330
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainNames: JArray
  ##              : A list of domain names.
  section = newJObject()
  var valid_21626331 = formData.getOrDefault("DomainNames")
  valid_21626331 = validateParameter(valid_21626331, JArray, required = false,
                                   default = nil)
  if valid_21626331 != nil:
    section.add "DomainNames", valid_21626331
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626332: Call_PostDescribeDomains_21626319; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default.
  ## 
  let valid = call_21626332.validator(path, query, header, formData, body, _)
  let scheme = call_21626332.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626332.makeUrl(scheme.get, call_21626332.host, call_21626332.base,
                               call_21626332.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626332, uri, valid, _)

proc call*(call_21626333: Call_PostDescribeDomains_21626319;
          DomainNames: JsonNode = nil; Action: string = "DescribeDomains";
          Version: string = "2011-02-01"): Recallable =
  ## postDescribeDomains
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default.
  ##   DomainNames: JArray
  ##              : A list of domain names.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626334 = newJObject()
  var formData_21626335 = newJObject()
  if DomainNames != nil:
    formData_21626335.add "DomainNames", DomainNames
  add(query_21626334, "Action", newJString(Action))
  add(query_21626334, "Version", newJString(Version))
  result = call_21626333.call(nil, query_21626334, nil, formData_21626335, nil)

var postDescribeDomains* = Call_PostDescribeDomains_21626319(
    name: "postDescribeDomains", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeDomains",
    validator: validate_PostDescribeDomains_21626320, base: "/",
    makeUrl: url_PostDescribeDomains_21626321,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeDomains_21626303 = ref object of OpenApiRestCall_21625435
proc url_GetDescribeDomains_21626305(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeDomains_21626304(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626306 = query.getOrDefault("DomainNames")
  valid_21626306 = validateParameter(valid_21626306, JArray, required = false,
                                   default = nil)
  if valid_21626306 != nil:
    section.add "DomainNames", valid_21626306
  var valid_21626307 = query.getOrDefault("Action")
  valid_21626307 = validateParameter(valid_21626307, JString, required = true,
                                   default = newJString("DescribeDomains"))
  if valid_21626307 != nil:
    section.add "Action", valid_21626307
  var valid_21626308 = query.getOrDefault("Version")
  valid_21626308 = validateParameter(valid_21626308, JString, required = true,
                                   default = newJString("2011-02-01"))
  if valid_21626308 != nil:
    section.add "Version", valid_21626308
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
  var valid_21626309 = header.getOrDefault("X-Amz-Date")
  valid_21626309 = validateParameter(valid_21626309, JString, required = false,
                                   default = nil)
  if valid_21626309 != nil:
    section.add "X-Amz-Date", valid_21626309
  var valid_21626310 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626310 = validateParameter(valid_21626310, JString, required = false,
                                   default = nil)
  if valid_21626310 != nil:
    section.add "X-Amz-Security-Token", valid_21626310
  var valid_21626311 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626311 = validateParameter(valid_21626311, JString, required = false,
                                   default = nil)
  if valid_21626311 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626311
  var valid_21626312 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626312 = validateParameter(valid_21626312, JString, required = false,
                                   default = nil)
  if valid_21626312 != nil:
    section.add "X-Amz-Algorithm", valid_21626312
  var valid_21626313 = header.getOrDefault("X-Amz-Signature")
  valid_21626313 = validateParameter(valid_21626313, JString, required = false,
                                   default = nil)
  if valid_21626313 != nil:
    section.add "X-Amz-Signature", valid_21626313
  var valid_21626314 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626314 = validateParameter(valid_21626314, JString, required = false,
                                   default = nil)
  if valid_21626314 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626314
  var valid_21626315 = header.getOrDefault("X-Amz-Credential")
  valid_21626315 = validateParameter(valid_21626315, JString, required = false,
                                   default = nil)
  if valid_21626315 != nil:
    section.add "X-Amz-Credential", valid_21626315
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626316: Call_GetDescribeDomains_21626303; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default.
  ## 
  let valid = call_21626316.validator(path, query, header, formData, body, _)
  let scheme = call_21626316.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626316.makeUrl(scheme.get, call_21626316.host, call_21626316.base,
                               call_21626316.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626316, uri, valid, _)

proc call*(call_21626317: Call_GetDescribeDomains_21626303;
          DomainNames: JsonNode = nil; Action: string = "DescribeDomains";
          Version: string = "2011-02-01"): Recallable =
  ## getDescribeDomains
  ## Gets information about the search domains owned by this account. Can be limited to specific domains. Shows all domains by default.
  ##   DomainNames: JArray
  ##              : A list of domain names.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626318 = newJObject()
  if DomainNames != nil:
    query_21626318.add "DomainNames", DomainNames
  add(query_21626318, "Action", newJString(Action))
  add(query_21626318, "Version", newJString(Version))
  result = call_21626317.call(nil, query_21626318, nil, nil, nil)

var getDescribeDomains* = Call_GetDescribeDomains_21626303(
    name: "getDescribeDomains", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeDomains",
    validator: validate_GetDescribeDomains_21626304, base: "/",
    makeUrl: url_GetDescribeDomains_21626305, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeIndexFields_21626353 = ref object of OpenApiRestCall_21625435
proc url_PostDescribeIndexFields_21626355(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeIndexFields_21626354(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626356 = query.getOrDefault("Action")
  valid_21626356 = validateParameter(valid_21626356, JString, required = true,
                                   default = newJString("DescribeIndexFields"))
  if valid_21626356 != nil:
    section.add "Action", valid_21626356
  var valid_21626357 = query.getOrDefault("Version")
  valid_21626357 = validateParameter(valid_21626357, JString, required = true,
                                   default = newJString("2011-02-01"))
  if valid_21626357 != nil:
    section.add "Version", valid_21626357
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
  var valid_21626358 = header.getOrDefault("X-Amz-Date")
  valid_21626358 = validateParameter(valid_21626358, JString, required = false,
                                   default = nil)
  if valid_21626358 != nil:
    section.add "X-Amz-Date", valid_21626358
  var valid_21626359 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626359 = validateParameter(valid_21626359, JString, required = false,
                                   default = nil)
  if valid_21626359 != nil:
    section.add "X-Amz-Security-Token", valid_21626359
  var valid_21626360 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626360 = validateParameter(valid_21626360, JString, required = false,
                                   default = nil)
  if valid_21626360 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626360
  var valid_21626361 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626361 = validateParameter(valid_21626361, JString, required = false,
                                   default = nil)
  if valid_21626361 != nil:
    section.add "X-Amz-Algorithm", valid_21626361
  var valid_21626362 = header.getOrDefault("X-Amz-Signature")
  valid_21626362 = validateParameter(valid_21626362, JString, required = false,
                                   default = nil)
  if valid_21626362 != nil:
    section.add "X-Amz-Signature", valid_21626362
  var valid_21626363 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626363 = validateParameter(valid_21626363, JString, required = false,
                                   default = nil)
  if valid_21626363 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626363
  var valid_21626364 = header.getOrDefault("X-Amz-Credential")
  valid_21626364 = validateParameter(valid_21626364, JString, required = false,
                                   default = nil)
  if valid_21626364 != nil:
    section.add "X-Amz-Credential", valid_21626364
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   FieldNames: JArray
  ##             : Limits the <code>DescribeIndexFields</code> response to the specified fields.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_21626365 = formData.getOrDefault("DomainName")
  valid_21626365 = validateParameter(valid_21626365, JString, required = true,
                                   default = nil)
  if valid_21626365 != nil:
    section.add "DomainName", valid_21626365
  var valid_21626366 = formData.getOrDefault("FieldNames")
  valid_21626366 = validateParameter(valid_21626366, JArray, required = false,
                                   default = nil)
  if valid_21626366 != nil:
    section.add "FieldNames", valid_21626366
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626367: Call_PostDescribeIndexFields_21626353;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. Shows all fields by default.
  ## 
  let valid = call_21626367.validator(path, query, header, formData, body, _)
  let scheme = call_21626367.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626367.makeUrl(scheme.get, call_21626367.host, call_21626367.base,
                               call_21626367.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626367, uri, valid, _)

proc call*(call_21626368: Call_PostDescribeIndexFields_21626353;
          DomainName: string; Action: string = "DescribeIndexFields";
          FieldNames: JsonNode = nil; Version: string = "2011-02-01"): Recallable =
  ## postDescribeIndexFields
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. Shows all fields by default.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   FieldNames: JArray
  ##             : Limits the <code>DescribeIndexFields</code> response to the specified fields.
  ##   Version: string (required)
  var query_21626369 = newJObject()
  var formData_21626370 = newJObject()
  add(formData_21626370, "DomainName", newJString(DomainName))
  add(query_21626369, "Action", newJString(Action))
  if FieldNames != nil:
    formData_21626370.add "FieldNames", FieldNames
  add(query_21626369, "Version", newJString(Version))
  result = call_21626368.call(nil, query_21626369, nil, formData_21626370, nil)

var postDescribeIndexFields* = Call_PostDescribeIndexFields_21626353(
    name: "postDescribeIndexFields", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeIndexFields",
    validator: validate_PostDescribeIndexFields_21626354, base: "/",
    makeUrl: url_PostDescribeIndexFields_21626355,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeIndexFields_21626336 = ref object of OpenApiRestCall_21625435
proc url_GetDescribeIndexFields_21626338(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeIndexFields_21626337(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626339 = query.getOrDefault("FieldNames")
  valid_21626339 = validateParameter(valid_21626339, JArray, required = false,
                                   default = nil)
  if valid_21626339 != nil:
    section.add "FieldNames", valid_21626339
  var valid_21626340 = query.getOrDefault("Action")
  valid_21626340 = validateParameter(valid_21626340, JString, required = true,
                                   default = newJString("DescribeIndexFields"))
  if valid_21626340 != nil:
    section.add "Action", valid_21626340
  var valid_21626341 = query.getOrDefault("DomainName")
  valid_21626341 = validateParameter(valid_21626341, JString, required = true,
                                   default = nil)
  if valid_21626341 != nil:
    section.add "DomainName", valid_21626341
  var valid_21626342 = query.getOrDefault("Version")
  valid_21626342 = validateParameter(valid_21626342, JString, required = true,
                                   default = newJString("2011-02-01"))
  if valid_21626342 != nil:
    section.add "Version", valid_21626342
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
  var valid_21626343 = header.getOrDefault("X-Amz-Date")
  valid_21626343 = validateParameter(valid_21626343, JString, required = false,
                                   default = nil)
  if valid_21626343 != nil:
    section.add "X-Amz-Date", valid_21626343
  var valid_21626344 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626344 = validateParameter(valid_21626344, JString, required = false,
                                   default = nil)
  if valid_21626344 != nil:
    section.add "X-Amz-Security-Token", valid_21626344
  var valid_21626345 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626345 = validateParameter(valid_21626345, JString, required = false,
                                   default = nil)
  if valid_21626345 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626345
  var valid_21626346 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626346 = validateParameter(valid_21626346, JString, required = false,
                                   default = nil)
  if valid_21626346 != nil:
    section.add "X-Amz-Algorithm", valid_21626346
  var valid_21626347 = header.getOrDefault("X-Amz-Signature")
  valid_21626347 = validateParameter(valid_21626347, JString, required = false,
                                   default = nil)
  if valid_21626347 != nil:
    section.add "X-Amz-Signature", valid_21626347
  var valid_21626348 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626348 = validateParameter(valid_21626348, JString, required = false,
                                   default = nil)
  if valid_21626348 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626348
  var valid_21626349 = header.getOrDefault("X-Amz-Credential")
  valid_21626349 = validateParameter(valid_21626349, JString, required = false,
                                   default = nil)
  if valid_21626349 != nil:
    section.add "X-Amz-Credential", valid_21626349
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626350: Call_GetDescribeIndexFields_21626336;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about the index fields configured for the search domain. Can be limited to specific fields by name. Shows all fields by default.
  ## 
  let valid = call_21626350.validator(path, query, header, formData, body, _)
  let scheme = call_21626350.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626350.makeUrl(scheme.get, call_21626350.host, call_21626350.base,
                               call_21626350.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626350, uri, valid, _)

proc call*(call_21626351: Call_GetDescribeIndexFields_21626336; DomainName: string;
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
  var query_21626352 = newJObject()
  if FieldNames != nil:
    query_21626352.add "FieldNames", FieldNames
  add(query_21626352, "Action", newJString(Action))
  add(query_21626352, "DomainName", newJString(DomainName))
  add(query_21626352, "Version", newJString(Version))
  result = call_21626351.call(nil, query_21626352, nil, nil, nil)

var getDescribeIndexFields* = Call_GetDescribeIndexFields_21626336(
    name: "getDescribeIndexFields", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeIndexFields",
    validator: validate_GetDescribeIndexFields_21626337, base: "/",
    makeUrl: url_GetDescribeIndexFields_21626338,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeRankExpressions_21626388 = ref object of OpenApiRestCall_21625435
proc url_PostDescribeRankExpressions_21626390(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeRankExpressions_21626389(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626391 = query.getOrDefault("Action")
  valid_21626391 = validateParameter(valid_21626391, JString, required = true, default = newJString(
      "DescribeRankExpressions"))
  if valid_21626391 != nil:
    section.add "Action", valid_21626391
  var valid_21626392 = query.getOrDefault("Version")
  valid_21626392 = validateParameter(valid_21626392, JString, required = true,
                                   default = newJString("2011-02-01"))
  if valid_21626392 != nil:
    section.add "Version", valid_21626392
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
  var valid_21626393 = header.getOrDefault("X-Amz-Date")
  valid_21626393 = validateParameter(valid_21626393, JString, required = false,
                                   default = nil)
  if valid_21626393 != nil:
    section.add "X-Amz-Date", valid_21626393
  var valid_21626394 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626394 = validateParameter(valid_21626394, JString, required = false,
                                   default = nil)
  if valid_21626394 != nil:
    section.add "X-Amz-Security-Token", valid_21626394
  var valid_21626395 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626395 = validateParameter(valid_21626395, JString, required = false,
                                   default = nil)
  if valid_21626395 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626395
  var valid_21626396 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626396 = validateParameter(valid_21626396, JString, required = false,
                                   default = nil)
  if valid_21626396 != nil:
    section.add "X-Amz-Algorithm", valid_21626396
  var valid_21626397 = header.getOrDefault("X-Amz-Signature")
  valid_21626397 = validateParameter(valid_21626397, JString, required = false,
                                   default = nil)
  if valid_21626397 != nil:
    section.add "X-Amz-Signature", valid_21626397
  var valid_21626398 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626398 = validateParameter(valid_21626398, JString, required = false,
                                   default = nil)
  if valid_21626398 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626398
  var valid_21626399 = header.getOrDefault("X-Amz-Credential")
  valid_21626399 = validateParameter(valid_21626399, JString, required = false,
                                   default = nil)
  if valid_21626399 != nil:
    section.add "X-Amz-Credential", valid_21626399
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   RankNames: JArray
  ##            : Limits the <code>DescribeRankExpressions</code> response to the specified fields.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_21626400 = formData.getOrDefault("DomainName")
  valid_21626400 = validateParameter(valid_21626400, JString, required = true,
                                   default = nil)
  if valid_21626400 != nil:
    section.add "DomainName", valid_21626400
  var valid_21626401 = formData.getOrDefault("RankNames")
  valid_21626401 = validateParameter(valid_21626401, JArray, required = false,
                                   default = nil)
  if valid_21626401 != nil:
    section.add "RankNames", valid_21626401
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626402: Call_PostDescribeRankExpressions_21626388;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the rank expressions configured for the search domain. Can be limited to specific rank expressions by name. Shows all rank expressions by default. 
  ## 
  let valid = call_21626402.validator(path, query, header, formData, body, _)
  let scheme = call_21626402.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626402.makeUrl(scheme.get, call_21626402.host, call_21626402.base,
                               call_21626402.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626402, uri, valid, _)

proc call*(call_21626403: Call_PostDescribeRankExpressions_21626388;
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
  var query_21626404 = newJObject()
  var formData_21626405 = newJObject()
  add(formData_21626405, "DomainName", newJString(DomainName))
  add(query_21626404, "Action", newJString(Action))
  if RankNames != nil:
    formData_21626405.add "RankNames", RankNames
  add(query_21626404, "Version", newJString(Version))
  result = call_21626403.call(nil, query_21626404, nil, formData_21626405, nil)

var postDescribeRankExpressions* = Call_PostDescribeRankExpressions_21626388(
    name: "postDescribeRankExpressions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeRankExpressions",
    validator: validate_PostDescribeRankExpressions_21626389, base: "/",
    makeUrl: url_PostDescribeRankExpressions_21626390,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeRankExpressions_21626371 = ref object of OpenApiRestCall_21625435
proc url_GetDescribeRankExpressions_21626373(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeRankExpressions_21626372(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626374 = query.getOrDefault("RankNames")
  valid_21626374 = validateParameter(valid_21626374, JArray, required = false,
                                   default = nil)
  if valid_21626374 != nil:
    section.add "RankNames", valid_21626374
  var valid_21626375 = query.getOrDefault("Action")
  valid_21626375 = validateParameter(valid_21626375, JString, required = true, default = newJString(
      "DescribeRankExpressions"))
  if valid_21626375 != nil:
    section.add "Action", valid_21626375
  var valid_21626376 = query.getOrDefault("DomainName")
  valid_21626376 = validateParameter(valid_21626376, JString, required = true,
                                   default = nil)
  if valid_21626376 != nil:
    section.add "DomainName", valid_21626376
  var valid_21626377 = query.getOrDefault("Version")
  valid_21626377 = validateParameter(valid_21626377, JString, required = true,
                                   default = newJString("2011-02-01"))
  if valid_21626377 != nil:
    section.add "Version", valid_21626377
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
  var valid_21626378 = header.getOrDefault("X-Amz-Date")
  valid_21626378 = validateParameter(valid_21626378, JString, required = false,
                                   default = nil)
  if valid_21626378 != nil:
    section.add "X-Amz-Date", valid_21626378
  var valid_21626379 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626379 = validateParameter(valid_21626379, JString, required = false,
                                   default = nil)
  if valid_21626379 != nil:
    section.add "X-Amz-Security-Token", valid_21626379
  var valid_21626380 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626380 = validateParameter(valid_21626380, JString, required = false,
                                   default = nil)
  if valid_21626380 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626380
  var valid_21626381 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626381 = validateParameter(valid_21626381, JString, required = false,
                                   default = nil)
  if valid_21626381 != nil:
    section.add "X-Amz-Algorithm", valid_21626381
  var valid_21626382 = header.getOrDefault("X-Amz-Signature")
  valid_21626382 = validateParameter(valid_21626382, JString, required = false,
                                   default = nil)
  if valid_21626382 != nil:
    section.add "X-Amz-Signature", valid_21626382
  var valid_21626383 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626383 = validateParameter(valid_21626383, JString, required = false,
                                   default = nil)
  if valid_21626383 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626383
  var valid_21626384 = header.getOrDefault("X-Amz-Credential")
  valid_21626384 = validateParameter(valid_21626384, JString, required = false,
                                   default = nil)
  if valid_21626384 != nil:
    section.add "X-Amz-Credential", valid_21626384
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626385: Call_GetDescribeRankExpressions_21626371;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the rank expressions configured for the search domain. Can be limited to specific rank expressions by name. Shows all rank expressions by default. 
  ## 
  let valid = call_21626385.validator(path, query, header, formData, body, _)
  let scheme = call_21626385.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626385.makeUrl(scheme.get, call_21626385.host, call_21626385.base,
                               call_21626385.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626385, uri, valid, _)

proc call*(call_21626386: Call_GetDescribeRankExpressions_21626371;
          DomainName: string; RankNames: JsonNode = nil;
          Action: string = "DescribeRankExpressions"; Version: string = "2011-02-01"): Recallable =
  ## getDescribeRankExpressions
  ## Gets the rank expressions configured for the search domain. Can be limited to specific rank expressions by name. Shows all rank expressions by default. 
  ##   RankNames: JArray
  ##            : Limits the <code>DescribeRankExpressions</code> response to the specified fields.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_21626387 = newJObject()
  if RankNames != nil:
    query_21626387.add "RankNames", RankNames
  add(query_21626387, "Action", newJString(Action))
  add(query_21626387, "DomainName", newJString(DomainName))
  add(query_21626387, "Version", newJString(Version))
  result = call_21626386.call(nil, query_21626387, nil, nil, nil)

var getDescribeRankExpressions* = Call_GetDescribeRankExpressions_21626371(
    name: "getDescribeRankExpressions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeRankExpressions",
    validator: validate_GetDescribeRankExpressions_21626372, base: "/",
    makeUrl: url_GetDescribeRankExpressions_21626373,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeServiceAccessPolicies_21626422 = ref object of OpenApiRestCall_21625435
proc url_PostDescribeServiceAccessPolicies_21626424(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeServiceAccessPolicies_21626423(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626425 = query.getOrDefault("Action")
  valid_21626425 = validateParameter(valid_21626425, JString, required = true, default = newJString(
      "DescribeServiceAccessPolicies"))
  if valid_21626425 != nil:
    section.add "Action", valid_21626425
  var valid_21626426 = query.getOrDefault("Version")
  valid_21626426 = validateParameter(valid_21626426, JString, required = true,
                                   default = newJString("2011-02-01"))
  if valid_21626426 != nil:
    section.add "Version", valid_21626426
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
  var valid_21626427 = header.getOrDefault("X-Amz-Date")
  valid_21626427 = validateParameter(valid_21626427, JString, required = false,
                                   default = nil)
  if valid_21626427 != nil:
    section.add "X-Amz-Date", valid_21626427
  var valid_21626428 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626428 = validateParameter(valid_21626428, JString, required = false,
                                   default = nil)
  if valid_21626428 != nil:
    section.add "X-Amz-Security-Token", valid_21626428
  var valid_21626429 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626429 = validateParameter(valid_21626429, JString, required = false,
                                   default = nil)
  if valid_21626429 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626429
  var valid_21626430 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626430 = validateParameter(valid_21626430, JString, required = false,
                                   default = nil)
  if valid_21626430 != nil:
    section.add "X-Amz-Algorithm", valid_21626430
  var valid_21626431 = header.getOrDefault("X-Amz-Signature")
  valid_21626431 = validateParameter(valid_21626431, JString, required = false,
                                   default = nil)
  if valid_21626431 != nil:
    section.add "X-Amz-Signature", valid_21626431
  var valid_21626432 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626432 = validateParameter(valid_21626432, JString, required = false,
                                   default = nil)
  if valid_21626432 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626432
  var valid_21626433 = header.getOrDefault("X-Amz-Credential")
  valid_21626433 = validateParameter(valid_21626433, JString, required = false,
                                   default = nil)
  if valid_21626433 != nil:
    section.add "X-Amz-Credential", valid_21626433
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_21626434 = formData.getOrDefault("DomainName")
  valid_21626434 = validateParameter(valid_21626434, JString, required = true,
                                   default = nil)
  if valid_21626434 != nil:
    section.add "DomainName", valid_21626434
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626435: Call_PostDescribeServiceAccessPolicies_21626422;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about the resource-based policies that control access to the domain's document and search services.
  ## 
  let valid = call_21626435.validator(path, query, header, formData, body, _)
  let scheme = call_21626435.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626435.makeUrl(scheme.get, call_21626435.host, call_21626435.base,
                               call_21626435.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626435, uri, valid, _)

proc call*(call_21626436: Call_PostDescribeServiceAccessPolicies_21626422;
          DomainName: string; Action: string = "DescribeServiceAccessPolicies";
          Version: string = "2011-02-01"): Recallable =
  ## postDescribeServiceAccessPolicies
  ## Gets information about the resource-based policies that control access to the domain's document and search services.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626437 = newJObject()
  var formData_21626438 = newJObject()
  add(formData_21626438, "DomainName", newJString(DomainName))
  add(query_21626437, "Action", newJString(Action))
  add(query_21626437, "Version", newJString(Version))
  result = call_21626436.call(nil, query_21626437, nil, formData_21626438, nil)

var postDescribeServiceAccessPolicies* = Call_PostDescribeServiceAccessPolicies_21626422(
    name: "postDescribeServiceAccessPolicies", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeServiceAccessPolicies",
    validator: validate_PostDescribeServiceAccessPolicies_21626423, base: "/",
    makeUrl: url_PostDescribeServiceAccessPolicies_21626424,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeServiceAccessPolicies_21626406 = ref object of OpenApiRestCall_21625435
proc url_GetDescribeServiceAccessPolicies_21626408(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeServiceAccessPolicies_21626407(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626409 = query.getOrDefault("Action")
  valid_21626409 = validateParameter(valid_21626409, JString, required = true, default = newJString(
      "DescribeServiceAccessPolicies"))
  if valid_21626409 != nil:
    section.add "Action", valid_21626409
  var valid_21626410 = query.getOrDefault("DomainName")
  valid_21626410 = validateParameter(valid_21626410, JString, required = true,
                                   default = nil)
  if valid_21626410 != nil:
    section.add "DomainName", valid_21626410
  var valid_21626411 = query.getOrDefault("Version")
  valid_21626411 = validateParameter(valid_21626411, JString, required = true,
                                   default = newJString("2011-02-01"))
  if valid_21626411 != nil:
    section.add "Version", valid_21626411
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
  var valid_21626412 = header.getOrDefault("X-Amz-Date")
  valid_21626412 = validateParameter(valid_21626412, JString, required = false,
                                   default = nil)
  if valid_21626412 != nil:
    section.add "X-Amz-Date", valid_21626412
  var valid_21626413 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626413 = validateParameter(valid_21626413, JString, required = false,
                                   default = nil)
  if valid_21626413 != nil:
    section.add "X-Amz-Security-Token", valid_21626413
  var valid_21626414 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626414 = validateParameter(valid_21626414, JString, required = false,
                                   default = nil)
  if valid_21626414 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626414
  var valid_21626415 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626415 = validateParameter(valid_21626415, JString, required = false,
                                   default = nil)
  if valid_21626415 != nil:
    section.add "X-Amz-Algorithm", valid_21626415
  var valid_21626416 = header.getOrDefault("X-Amz-Signature")
  valid_21626416 = validateParameter(valid_21626416, JString, required = false,
                                   default = nil)
  if valid_21626416 != nil:
    section.add "X-Amz-Signature", valid_21626416
  var valid_21626417 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626417 = validateParameter(valid_21626417, JString, required = false,
                                   default = nil)
  if valid_21626417 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626417
  var valid_21626418 = header.getOrDefault("X-Amz-Credential")
  valid_21626418 = validateParameter(valid_21626418, JString, required = false,
                                   default = nil)
  if valid_21626418 != nil:
    section.add "X-Amz-Credential", valid_21626418
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626419: Call_GetDescribeServiceAccessPolicies_21626406;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about the resource-based policies that control access to the domain's document and search services.
  ## 
  let valid = call_21626419.validator(path, query, header, formData, body, _)
  let scheme = call_21626419.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626419.makeUrl(scheme.get, call_21626419.host, call_21626419.base,
                               call_21626419.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626419, uri, valid, _)

proc call*(call_21626420: Call_GetDescribeServiceAccessPolicies_21626406;
          DomainName: string; Action: string = "DescribeServiceAccessPolicies";
          Version: string = "2011-02-01"): Recallable =
  ## getDescribeServiceAccessPolicies
  ## Gets information about the resource-based policies that control access to the domain's document and search services.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_21626421 = newJObject()
  add(query_21626421, "Action", newJString(Action))
  add(query_21626421, "DomainName", newJString(DomainName))
  add(query_21626421, "Version", newJString(Version))
  result = call_21626420.call(nil, query_21626421, nil, nil, nil)

var getDescribeServiceAccessPolicies* = Call_GetDescribeServiceAccessPolicies_21626406(
    name: "getDescribeServiceAccessPolicies", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=DescribeServiceAccessPolicies",
    validator: validate_GetDescribeServiceAccessPolicies_21626407, base: "/",
    makeUrl: url_GetDescribeServiceAccessPolicies_21626408,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeStemmingOptions_21626455 = ref object of OpenApiRestCall_21625435
proc url_PostDescribeStemmingOptions_21626457(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeStemmingOptions_21626456(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626458 = query.getOrDefault("Action")
  valid_21626458 = validateParameter(valid_21626458, JString, required = true, default = newJString(
      "DescribeStemmingOptions"))
  if valid_21626458 != nil:
    section.add "Action", valid_21626458
  var valid_21626459 = query.getOrDefault("Version")
  valid_21626459 = validateParameter(valid_21626459, JString, required = true,
                                   default = newJString("2011-02-01"))
  if valid_21626459 != nil:
    section.add "Version", valid_21626459
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
  var valid_21626460 = header.getOrDefault("X-Amz-Date")
  valid_21626460 = validateParameter(valid_21626460, JString, required = false,
                                   default = nil)
  if valid_21626460 != nil:
    section.add "X-Amz-Date", valid_21626460
  var valid_21626461 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626461 = validateParameter(valid_21626461, JString, required = false,
                                   default = nil)
  if valid_21626461 != nil:
    section.add "X-Amz-Security-Token", valid_21626461
  var valid_21626462 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626462 = validateParameter(valid_21626462, JString, required = false,
                                   default = nil)
  if valid_21626462 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626462
  var valid_21626463 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626463 = validateParameter(valid_21626463, JString, required = false,
                                   default = nil)
  if valid_21626463 != nil:
    section.add "X-Amz-Algorithm", valid_21626463
  var valid_21626464 = header.getOrDefault("X-Amz-Signature")
  valid_21626464 = validateParameter(valid_21626464, JString, required = false,
                                   default = nil)
  if valid_21626464 != nil:
    section.add "X-Amz-Signature", valid_21626464
  var valid_21626465 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626465 = validateParameter(valid_21626465, JString, required = false,
                                   default = nil)
  if valid_21626465 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626465
  var valid_21626466 = header.getOrDefault("X-Amz-Credential")
  valid_21626466 = validateParameter(valid_21626466, JString, required = false,
                                   default = nil)
  if valid_21626466 != nil:
    section.add "X-Amz-Credential", valid_21626466
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_21626467 = formData.getOrDefault("DomainName")
  valid_21626467 = validateParameter(valid_21626467, JString, required = true,
                                   default = nil)
  if valid_21626467 != nil:
    section.add "DomainName", valid_21626467
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626468: Call_PostDescribeStemmingOptions_21626455;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the stemming dictionary configured for the search domain.
  ## 
  let valid = call_21626468.validator(path, query, header, formData, body, _)
  let scheme = call_21626468.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626468.makeUrl(scheme.get, call_21626468.host, call_21626468.base,
                               call_21626468.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626468, uri, valid, _)

proc call*(call_21626469: Call_PostDescribeStemmingOptions_21626455;
          DomainName: string; Action: string = "DescribeStemmingOptions";
          Version: string = "2011-02-01"): Recallable =
  ## postDescribeStemmingOptions
  ## Gets the stemming dictionary configured for the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626470 = newJObject()
  var formData_21626471 = newJObject()
  add(formData_21626471, "DomainName", newJString(DomainName))
  add(query_21626470, "Action", newJString(Action))
  add(query_21626470, "Version", newJString(Version))
  result = call_21626469.call(nil, query_21626470, nil, formData_21626471, nil)

var postDescribeStemmingOptions* = Call_PostDescribeStemmingOptions_21626455(
    name: "postDescribeStemmingOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeStemmingOptions",
    validator: validate_PostDescribeStemmingOptions_21626456, base: "/",
    makeUrl: url_PostDescribeStemmingOptions_21626457,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeStemmingOptions_21626439 = ref object of OpenApiRestCall_21625435
proc url_GetDescribeStemmingOptions_21626441(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeStemmingOptions_21626440(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626442 = query.getOrDefault("Action")
  valid_21626442 = validateParameter(valid_21626442, JString, required = true, default = newJString(
      "DescribeStemmingOptions"))
  if valid_21626442 != nil:
    section.add "Action", valid_21626442
  var valid_21626443 = query.getOrDefault("DomainName")
  valid_21626443 = validateParameter(valid_21626443, JString, required = true,
                                   default = nil)
  if valid_21626443 != nil:
    section.add "DomainName", valid_21626443
  var valid_21626444 = query.getOrDefault("Version")
  valid_21626444 = validateParameter(valid_21626444, JString, required = true,
                                   default = newJString("2011-02-01"))
  if valid_21626444 != nil:
    section.add "Version", valid_21626444
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
  var valid_21626445 = header.getOrDefault("X-Amz-Date")
  valid_21626445 = validateParameter(valid_21626445, JString, required = false,
                                   default = nil)
  if valid_21626445 != nil:
    section.add "X-Amz-Date", valid_21626445
  var valid_21626446 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626446 = validateParameter(valid_21626446, JString, required = false,
                                   default = nil)
  if valid_21626446 != nil:
    section.add "X-Amz-Security-Token", valid_21626446
  var valid_21626447 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626447 = validateParameter(valid_21626447, JString, required = false,
                                   default = nil)
  if valid_21626447 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626447
  var valid_21626448 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626448 = validateParameter(valid_21626448, JString, required = false,
                                   default = nil)
  if valid_21626448 != nil:
    section.add "X-Amz-Algorithm", valid_21626448
  var valid_21626449 = header.getOrDefault("X-Amz-Signature")
  valid_21626449 = validateParameter(valid_21626449, JString, required = false,
                                   default = nil)
  if valid_21626449 != nil:
    section.add "X-Amz-Signature", valid_21626449
  var valid_21626450 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626450 = validateParameter(valid_21626450, JString, required = false,
                                   default = nil)
  if valid_21626450 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626450
  var valid_21626451 = header.getOrDefault("X-Amz-Credential")
  valid_21626451 = validateParameter(valid_21626451, JString, required = false,
                                   default = nil)
  if valid_21626451 != nil:
    section.add "X-Amz-Credential", valid_21626451
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626452: Call_GetDescribeStemmingOptions_21626439;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the stemming dictionary configured for the search domain.
  ## 
  let valid = call_21626452.validator(path, query, header, formData, body, _)
  let scheme = call_21626452.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626452.makeUrl(scheme.get, call_21626452.host, call_21626452.base,
                               call_21626452.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626452, uri, valid, _)

proc call*(call_21626453: Call_GetDescribeStemmingOptions_21626439;
          DomainName: string; Action: string = "DescribeStemmingOptions";
          Version: string = "2011-02-01"): Recallable =
  ## getDescribeStemmingOptions
  ## Gets the stemming dictionary configured for the search domain.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_21626454 = newJObject()
  add(query_21626454, "Action", newJString(Action))
  add(query_21626454, "DomainName", newJString(DomainName))
  add(query_21626454, "Version", newJString(Version))
  result = call_21626453.call(nil, query_21626454, nil, nil, nil)

var getDescribeStemmingOptions* = Call_GetDescribeStemmingOptions_21626439(
    name: "getDescribeStemmingOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeStemmingOptions",
    validator: validate_GetDescribeStemmingOptions_21626440, base: "/",
    makeUrl: url_GetDescribeStemmingOptions_21626441,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeStopwordOptions_21626488 = ref object of OpenApiRestCall_21625435
proc url_PostDescribeStopwordOptions_21626490(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeStopwordOptions_21626489(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626491 = query.getOrDefault("Action")
  valid_21626491 = validateParameter(valid_21626491, JString, required = true, default = newJString(
      "DescribeStopwordOptions"))
  if valid_21626491 != nil:
    section.add "Action", valid_21626491
  var valid_21626492 = query.getOrDefault("Version")
  valid_21626492 = validateParameter(valid_21626492, JString, required = true,
                                   default = newJString("2011-02-01"))
  if valid_21626492 != nil:
    section.add "Version", valid_21626492
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
  var valid_21626493 = header.getOrDefault("X-Amz-Date")
  valid_21626493 = validateParameter(valid_21626493, JString, required = false,
                                   default = nil)
  if valid_21626493 != nil:
    section.add "X-Amz-Date", valid_21626493
  var valid_21626494 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626494 = validateParameter(valid_21626494, JString, required = false,
                                   default = nil)
  if valid_21626494 != nil:
    section.add "X-Amz-Security-Token", valid_21626494
  var valid_21626495 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626495 = validateParameter(valid_21626495, JString, required = false,
                                   default = nil)
  if valid_21626495 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626495
  var valid_21626496 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626496 = validateParameter(valid_21626496, JString, required = false,
                                   default = nil)
  if valid_21626496 != nil:
    section.add "X-Amz-Algorithm", valid_21626496
  var valid_21626497 = header.getOrDefault("X-Amz-Signature")
  valid_21626497 = validateParameter(valid_21626497, JString, required = false,
                                   default = nil)
  if valid_21626497 != nil:
    section.add "X-Amz-Signature", valid_21626497
  var valid_21626498 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626498 = validateParameter(valid_21626498, JString, required = false,
                                   default = nil)
  if valid_21626498 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626498
  var valid_21626499 = header.getOrDefault("X-Amz-Credential")
  valid_21626499 = validateParameter(valid_21626499, JString, required = false,
                                   default = nil)
  if valid_21626499 != nil:
    section.add "X-Amz-Credential", valid_21626499
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_21626500 = formData.getOrDefault("DomainName")
  valid_21626500 = validateParameter(valid_21626500, JString, required = true,
                                   default = nil)
  if valid_21626500 != nil:
    section.add "DomainName", valid_21626500
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626501: Call_PostDescribeStopwordOptions_21626488;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the stopwords configured for the search domain.
  ## 
  let valid = call_21626501.validator(path, query, header, formData, body, _)
  let scheme = call_21626501.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626501.makeUrl(scheme.get, call_21626501.host, call_21626501.base,
                               call_21626501.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626501, uri, valid, _)

proc call*(call_21626502: Call_PostDescribeStopwordOptions_21626488;
          DomainName: string; Action: string = "DescribeStopwordOptions";
          Version: string = "2011-02-01"): Recallable =
  ## postDescribeStopwordOptions
  ## Gets the stopwords configured for the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626503 = newJObject()
  var formData_21626504 = newJObject()
  add(formData_21626504, "DomainName", newJString(DomainName))
  add(query_21626503, "Action", newJString(Action))
  add(query_21626503, "Version", newJString(Version))
  result = call_21626502.call(nil, query_21626503, nil, formData_21626504, nil)

var postDescribeStopwordOptions* = Call_PostDescribeStopwordOptions_21626488(
    name: "postDescribeStopwordOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeStopwordOptions",
    validator: validate_PostDescribeStopwordOptions_21626489, base: "/",
    makeUrl: url_PostDescribeStopwordOptions_21626490,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeStopwordOptions_21626472 = ref object of OpenApiRestCall_21625435
proc url_GetDescribeStopwordOptions_21626474(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeStopwordOptions_21626473(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626475 = query.getOrDefault("Action")
  valid_21626475 = validateParameter(valid_21626475, JString, required = true, default = newJString(
      "DescribeStopwordOptions"))
  if valid_21626475 != nil:
    section.add "Action", valid_21626475
  var valid_21626476 = query.getOrDefault("DomainName")
  valid_21626476 = validateParameter(valid_21626476, JString, required = true,
                                   default = nil)
  if valid_21626476 != nil:
    section.add "DomainName", valid_21626476
  var valid_21626477 = query.getOrDefault("Version")
  valid_21626477 = validateParameter(valid_21626477, JString, required = true,
                                   default = newJString("2011-02-01"))
  if valid_21626477 != nil:
    section.add "Version", valid_21626477
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
  var valid_21626478 = header.getOrDefault("X-Amz-Date")
  valid_21626478 = validateParameter(valid_21626478, JString, required = false,
                                   default = nil)
  if valid_21626478 != nil:
    section.add "X-Amz-Date", valid_21626478
  var valid_21626479 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626479 = validateParameter(valid_21626479, JString, required = false,
                                   default = nil)
  if valid_21626479 != nil:
    section.add "X-Amz-Security-Token", valid_21626479
  var valid_21626480 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626480 = validateParameter(valid_21626480, JString, required = false,
                                   default = nil)
  if valid_21626480 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626480
  var valid_21626481 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626481 = validateParameter(valid_21626481, JString, required = false,
                                   default = nil)
  if valid_21626481 != nil:
    section.add "X-Amz-Algorithm", valid_21626481
  var valid_21626482 = header.getOrDefault("X-Amz-Signature")
  valid_21626482 = validateParameter(valid_21626482, JString, required = false,
                                   default = nil)
  if valid_21626482 != nil:
    section.add "X-Amz-Signature", valid_21626482
  var valid_21626483 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626483 = validateParameter(valid_21626483, JString, required = false,
                                   default = nil)
  if valid_21626483 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626483
  var valid_21626484 = header.getOrDefault("X-Amz-Credential")
  valid_21626484 = validateParameter(valid_21626484, JString, required = false,
                                   default = nil)
  if valid_21626484 != nil:
    section.add "X-Amz-Credential", valid_21626484
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626485: Call_GetDescribeStopwordOptions_21626472;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the stopwords configured for the search domain.
  ## 
  let valid = call_21626485.validator(path, query, header, formData, body, _)
  let scheme = call_21626485.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626485.makeUrl(scheme.get, call_21626485.host, call_21626485.base,
                               call_21626485.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626485, uri, valid, _)

proc call*(call_21626486: Call_GetDescribeStopwordOptions_21626472;
          DomainName: string; Action: string = "DescribeStopwordOptions";
          Version: string = "2011-02-01"): Recallable =
  ## getDescribeStopwordOptions
  ## Gets the stopwords configured for the search domain.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_21626487 = newJObject()
  add(query_21626487, "Action", newJString(Action))
  add(query_21626487, "DomainName", newJString(DomainName))
  add(query_21626487, "Version", newJString(Version))
  result = call_21626486.call(nil, query_21626487, nil, nil, nil)

var getDescribeStopwordOptions* = Call_GetDescribeStopwordOptions_21626472(
    name: "getDescribeStopwordOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeStopwordOptions",
    validator: validate_GetDescribeStopwordOptions_21626473, base: "/",
    makeUrl: url_GetDescribeStopwordOptions_21626474,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostDescribeSynonymOptions_21626521 = ref object of OpenApiRestCall_21625435
proc url_PostDescribeSynonymOptions_21626523(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostDescribeSynonymOptions_21626522(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626524 = query.getOrDefault("Action")
  valid_21626524 = validateParameter(valid_21626524, JString, required = true, default = newJString(
      "DescribeSynonymOptions"))
  if valid_21626524 != nil:
    section.add "Action", valid_21626524
  var valid_21626525 = query.getOrDefault("Version")
  valid_21626525 = validateParameter(valid_21626525, JString, required = true,
                                   default = newJString("2011-02-01"))
  if valid_21626525 != nil:
    section.add "Version", valid_21626525
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
  var valid_21626526 = header.getOrDefault("X-Amz-Date")
  valid_21626526 = validateParameter(valid_21626526, JString, required = false,
                                   default = nil)
  if valid_21626526 != nil:
    section.add "X-Amz-Date", valid_21626526
  var valid_21626527 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626527 = validateParameter(valid_21626527, JString, required = false,
                                   default = nil)
  if valid_21626527 != nil:
    section.add "X-Amz-Security-Token", valid_21626527
  var valid_21626528 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626528 = validateParameter(valid_21626528, JString, required = false,
                                   default = nil)
  if valid_21626528 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626528
  var valid_21626529 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626529 = validateParameter(valid_21626529, JString, required = false,
                                   default = nil)
  if valid_21626529 != nil:
    section.add "X-Amz-Algorithm", valid_21626529
  var valid_21626530 = header.getOrDefault("X-Amz-Signature")
  valid_21626530 = validateParameter(valid_21626530, JString, required = false,
                                   default = nil)
  if valid_21626530 != nil:
    section.add "X-Amz-Signature", valid_21626530
  var valid_21626531 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626531 = validateParameter(valid_21626531, JString, required = false,
                                   default = nil)
  if valid_21626531 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626531
  var valid_21626532 = header.getOrDefault("X-Amz-Credential")
  valid_21626532 = validateParameter(valid_21626532, JString, required = false,
                                   default = nil)
  if valid_21626532 != nil:
    section.add "X-Amz-Credential", valid_21626532
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_21626533 = formData.getOrDefault("DomainName")
  valid_21626533 = validateParameter(valid_21626533, JString, required = true,
                                   default = nil)
  if valid_21626533 != nil:
    section.add "DomainName", valid_21626533
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626534: Call_PostDescribeSynonymOptions_21626521;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the synonym dictionary configured for the search domain.
  ## 
  let valid = call_21626534.validator(path, query, header, formData, body, _)
  let scheme = call_21626534.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626534.makeUrl(scheme.get, call_21626534.host, call_21626534.base,
                               call_21626534.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626534, uri, valid, _)

proc call*(call_21626535: Call_PostDescribeSynonymOptions_21626521;
          DomainName: string; Action: string = "DescribeSynonymOptions";
          Version: string = "2011-02-01"): Recallable =
  ## postDescribeSynonymOptions
  ## Gets the synonym dictionary configured for the search domain.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626536 = newJObject()
  var formData_21626537 = newJObject()
  add(formData_21626537, "DomainName", newJString(DomainName))
  add(query_21626536, "Action", newJString(Action))
  add(query_21626536, "Version", newJString(Version))
  result = call_21626535.call(nil, query_21626536, nil, formData_21626537, nil)

var postDescribeSynonymOptions* = Call_PostDescribeSynonymOptions_21626521(
    name: "postDescribeSynonymOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeSynonymOptions",
    validator: validate_PostDescribeSynonymOptions_21626522, base: "/",
    makeUrl: url_PostDescribeSynonymOptions_21626523,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDescribeSynonymOptions_21626505 = ref object of OpenApiRestCall_21625435
proc url_GetDescribeSynonymOptions_21626507(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDescribeSynonymOptions_21626506(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626508 = query.getOrDefault("Action")
  valid_21626508 = validateParameter(valid_21626508, JString, required = true, default = newJString(
      "DescribeSynonymOptions"))
  if valid_21626508 != nil:
    section.add "Action", valid_21626508
  var valid_21626509 = query.getOrDefault("DomainName")
  valid_21626509 = validateParameter(valid_21626509, JString, required = true,
                                   default = nil)
  if valid_21626509 != nil:
    section.add "DomainName", valid_21626509
  var valid_21626510 = query.getOrDefault("Version")
  valid_21626510 = validateParameter(valid_21626510, JString, required = true,
                                   default = newJString("2011-02-01"))
  if valid_21626510 != nil:
    section.add "Version", valid_21626510
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
  var valid_21626511 = header.getOrDefault("X-Amz-Date")
  valid_21626511 = validateParameter(valid_21626511, JString, required = false,
                                   default = nil)
  if valid_21626511 != nil:
    section.add "X-Amz-Date", valid_21626511
  var valid_21626512 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626512 = validateParameter(valid_21626512, JString, required = false,
                                   default = nil)
  if valid_21626512 != nil:
    section.add "X-Amz-Security-Token", valid_21626512
  var valid_21626513 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626513 = validateParameter(valid_21626513, JString, required = false,
                                   default = nil)
  if valid_21626513 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626513
  var valid_21626514 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626514 = validateParameter(valid_21626514, JString, required = false,
                                   default = nil)
  if valid_21626514 != nil:
    section.add "X-Amz-Algorithm", valid_21626514
  var valid_21626515 = header.getOrDefault("X-Amz-Signature")
  valid_21626515 = validateParameter(valid_21626515, JString, required = false,
                                   default = nil)
  if valid_21626515 != nil:
    section.add "X-Amz-Signature", valid_21626515
  var valid_21626516 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626516 = validateParameter(valid_21626516, JString, required = false,
                                   default = nil)
  if valid_21626516 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626516
  var valid_21626517 = header.getOrDefault("X-Amz-Credential")
  valid_21626517 = validateParameter(valid_21626517, JString, required = false,
                                   default = nil)
  if valid_21626517 != nil:
    section.add "X-Amz-Credential", valid_21626517
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626518: Call_GetDescribeSynonymOptions_21626505;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the synonym dictionary configured for the search domain.
  ## 
  let valid = call_21626518.validator(path, query, header, formData, body, _)
  let scheme = call_21626518.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626518.makeUrl(scheme.get, call_21626518.host, call_21626518.base,
                               call_21626518.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626518, uri, valid, _)

proc call*(call_21626519: Call_GetDescribeSynonymOptions_21626505;
          DomainName: string; Action: string = "DescribeSynonymOptions";
          Version: string = "2011-02-01"): Recallable =
  ## getDescribeSynonymOptions
  ## Gets the synonym dictionary configured for the search domain.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_21626520 = newJObject()
  add(query_21626520, "Action", newJString(Action))
  add(query_21626520, "DomainName", newJString(DomainName))
  add(query_21626520, "Version", newJString(Version))
  result = call_21626519.call(nil, query_21626520, nil, nil, nil)

var getDescribeSynonymOptions* = Call_GetDescribeSynonymOptions_21626505(
    name: "getDescribeSynonymOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=DescribeSynonymOptions",
    validator: validate_GetDescribeSynonymOptions_21626506, base: "/",
    makeUrl: url_GetDescribeSynonymOptions_21626507,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostIndexDocuments_21626554 = ref object of OpenApiRestCall_21625435
proc url_PostIndexDocuments_21626556(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostIndexDocuments_21626555(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626557 = query.getOrDefault("Action")
  valid_21626557 = validateParameter(valid_21626557, JString, required = true,
                                   default = newJString("IndexDocuments"))
  if valid_21626557 != nil:
    section.add "Action", valid_21626557
  var valid_21626558 = query.getOrDefault("Version")
  valid_21626558 = validateParameter(valid_21626558, JString, required = true,
                                   default = newJString("2011-02-01"))
  if valid_21626558 != nil:
    section.add "Version", valid_21626558
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
  var valid_21626559 = header.getOrDefault("X-Amz-Date")
  valid_21626559 = validateParameter(valid_21626559, JString, required = false,
                                   default = nil)
  if valid_21626559 != nil:
    section.add "X-Amz-Date", valid_21626559
  var valid_21626560 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626560 = validateParameter(valid_21626560, JString, required = false,
                                   default = nil)
  if valid_21626560 != nil:
    section.add "X-Amz-Security-Token", valid_21626560
  var valid_21626561 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626561 = validateParameter(valid_21626561, JString, required = false,
                                   default = nil)
  if valid_21626561 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626561
  var valid_21626562 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626562 = validateParameter(valid_21626562, JString, required = false,
                                   default = nil)
  if valid_21626562 != nil:
    section.add "X-Amz-Algorithm", valid_21626562
  var valid_21626563 = header.getOrDefault("X-Amz-Signature")
  valid_21626563 = validateParameter(valid_21626563, JString, required = false,
                                   default = nil)
  if valid_21626563 != nil:
    section.add "X-Amz-Signature", valid_21626563
  var valid_21626564 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626564 = validateParameter(valid_21626564, JString, required = false,
                                   default = nil)
  if valid_21626564 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626564
  var valid_21626565 = header.getOrDefault("X-Amz-Credential")
  valid_21626565 = validateParameter(valid_21626565, JString, required = false,
                                   default = nil)
  if valid_21626565 != nil:
    section.add "X-Amz-Credential", valid_21626565
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_21626566 = formData.getOrDefault("DomainName")
  valid_21626566 = validateParameter(valid_21626566, JString, required = true,
                                   default = nil)
  if valid_21626566 != nil:
    section.add "DomainName", valid_21626566
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626567: Call_PostIndexDocuments_21626554; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Tells the search domain to start indexing its documents using the latest text processing options and <code>IndexFields</code>. This operation must be invoked to make options whose <a>OptionStatus</a> has <code>OptionState</code> of <code>RequiresIndexDocuments</code> visible in search results.
  ## 
  let valid = call_21626567.validator(path, query, header, formData, body, _)
  let scheme = call_21626567.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626567.makeUrl(scheme.get, call_21626567.host, call_21626567.base,
                               call_21626567.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626567, uri, valid, _)

proc call*(call_21626568: Call_PostIndexDocuments_21626554; DomainName: string;
          Action: string = "IndexDocuments"; Version: string = "2011-02-01"): Recallable =
  ## postIndexDocuments
  ## Tells the search domain to start indexing its documents using the latest text processing options and <code>IndexFields</code>. This operation must be invoked to make options whose <a>OptionStatus</a> has <code>OptionState</code> of <code>RequiresIndexDocuments</code> visible in search results.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626569 = newJObject()
  var formData_21626570 = newJObject()
  add(formData_21626570, "DomainName", newJString(DomainName))
  add(query_21626569, "Action", newJString(Action))
  add(query_21626569, "Version", newJString(Version))
  result = call_21626568.call(nil, query_21626569, nil, formData_21626570, nil)

var postIndexDocuments* = Call_PostIndexDocuments_21626554(
    name: "postIndexDocuments", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=IndexDocuments",
    validator: validate_PostIndexDocuments_21626555, base: "/",
    makeUrl: url_PostIndexDocuments_21626556, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetIndexDocuments_21626538 = ref object of OpenApiRestCall_21625435
proc url_GetIndexDocuments_21626540(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetIndexDocuments_21626539(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626541 = query.getOrDefault("Action")
  valid_21626541 = validateParameter(valid_21626541, JString, required = true,
                                   default = newJString("IndexDocuments"))
  if valid_21626541 != nil:
    section.add "Action", valid_21626541
  var valid_21626542 = query.getOrDefault("DomainName")
  valid_21626542 = validateParameter(valid_21626542, JString, required = true,
                                   default = nil)
  if valid_21626542 != nil:
    section.add "DomainName", valid_21626542
  var valid_21626543 = query.getOrDefault("Version")
  valid_21626543 = validateParameter(valid_21626543, JString, required = true,
                                   default = newJString("2011-02-01"))
  if valid_21626543 != nil:
    section.add "Version", valid_21626543
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
  var valid_21626544 = header.getOrDefault("X-Amz-Date")
  valid_21626544 = validateParameter(valid_21626544, JString, required = false,
                                   default = nil)
  if valid_21626544 != nil:
    section.add "X-Amz-Date", valid_21626544
  var valid_21626545 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626545 = validateParameter(valid_21626545, JString, required = false,
                                   default = nil)
  if valid_21626545 != nil:
    section.add "X-Amz-Security-Token", valid_21626545
  var valid_21626546 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626546 = validateParameter(valid_21626546, JString, required = false,
                                   default = nil)
  if valid_21626546 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626546
  var valid_21626547 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626547 = validateParameter(valid_21626547, JString, required = false,
                                   default = nil)
  if valid_21626547 != nil:
    section.add "X-Amz-Algorithm", valid_21626547
  var valid_21626548 = header.getOrDefault("X-Amz-Signature")
  valid_21626548 = validateParameter(valid_21626548, JString, required = false,
                                   default = nil)
  if valid_21626548 != nil:
    section.add "X-Amz-Signature", valid_21626548
  var valid_21626549 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626549 = validateParameter(valid_21626549, JString, required = false,
                                   default = nil)
  if valid_21626549 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626549
  var valid_21626550 = header.getOrDefault("X-Amz-Credential")
  valid_21626550 = validateParameter(valid_21626550, JString, required = false,
                                   default = nil)
  if valid_21626550 != nil:
    section.add "X-Amz-Credential", valid_21626550
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626551: Call_GetIndexDocuments_21626538; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Tells the search domain to start indexing its documents using the latest text processing options and <code>IndexFields</code>. This operation must be invoked to make options whose <a>OptionStatus</a> has <code>OptionState</code> of <code>RequiresIndexDocuments</code> visible in search results.
  ## 
  let valid = call_21626551.validator(path, query, header, formData, body, _)
  let scheme = call_21626551.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626551.makeUrl(scheme.get, call_21626551.host, call_21626551.base,
                               call_21626551.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626551, uri, valid, _)

proc call*(call_21626552: Call_GetIndexDocuments_21626538; DomainName: string;
          Action: string = "IndexDocuments"; Version: string = "2011-02-01"): Recallable =
  ## getIndexDocuments
  ## Tells the search domain to start indexing its documents using the latest text processing options and <code>IndexFields</code>. This operation must be invoked to make options whose <a>OptionStatus</a> has <code>OptionState</code> of <code>RequiresIndexDocuments</code> visible in search results.
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_21626553 = newJObject()
  add(query_21626553, "Action", newJString(Action))
  add(query_21626553, "DomainName", newJString(DomainName))
  add(query_21626553, "Version", newJString(Version))
  result = call_21626552.call(nil, query_21626553, nil, nil, nil)

var getIndexDocuments* = Call_GetIndexDocuments_21626538(name: "getIndexDocuments",
    meth: HttpMethod.HttpGet, host: "cloudsearch.amazonaws.com",
    route: "/#Action=IndexDocuments", validator: validate_GetIndexDocuments_21626539,
    base: "/", makeUrl: url_GetIndexDocuments_21626540,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateAvailabilityOptions_21626588 = ref object of OpenApiRestCall_21625435
proc url_PostUpdateAvailabilityOptions_21626590(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostUpdateAvailabilityOptions_21626589(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626591 = query.getOrDefault("Action")
  valid_21626591 = validateParameter(valid_21626591, JString, required = true, default = newJString(
      "UpdateAvailabilityOptions"))
  if valid_21626591 != nil:
    section.add "Action", valid_21626591
  var valid_21626592 = query.getOrDefault("Version")
  valid_21626592 = validateParameter(valid_21626592, JString, required = true,
                                   default = newJString("2011-02-01"))
  if valid_21626592 != nil:
    section.add "Version", valid_21626592
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
  var valid_21626593 = header.getOrDefault("X-Amz-Date")
  valid_21626593 = validateParameter(valid_21626593, JString, required = false,
                                   default = nil)
  if valid_21626593 != nil:
    section.add "X-Amz-Date", valid_21626593
  var valid_21626594 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626594 = validateParameter(valid_21626594, JString, required = false,
                                   default = nil)
  if valid_21626594 != nil:
    section.add "X-Amz-Security-Token", valid_21626594
  var valid_21626595 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626595 = validateParameter(valid_21626595, JString, required = false,
                                   default = nil)
  if valid_21626595 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626595
  var valid_21626596 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626596 = validateParameter(valid_21626596, JString, required = false,
                                   default = nil)
  if valid_21626596 != nil:
    section.add "X-Amz-Algorithm", valid_21626596
  var valid_21626597 = header.getOrDefault("X-Amz-Signature")
  valid_21626597 = validateParameter(valid_21626597, JString, required = false,
                                   default = nil)
  if valid_21626597 != nil:
    section.add "X-Amz-Signature", valid_21626597
  var valid_21626598 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626598 = validateParameter(valid_21626598, JString, required = false,
                                   default = nil)
  if valid_21626598 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626598
  var valid_21626599 = header.getOrDefault("X-Amz-Credential")
  valid_21626599 = validateParameter(valid_21626599, JString, required = false,
                                   default = nil)
  if valid_21626599 != nil:
    section.add "X-Amz-Credential", valid_21626599
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   MultiAZ: JBool (required)
  ##          : You expand an existing search domain to a second Availability Zone by setting the Multi-AZ option to true. Similarly, you can turn off the Multi-AZ option to downgrade the domain to a single Availability Zone by setting the Multi-AZ option to <code>false</code>. 
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_21626600 = formData.getOrDefault("DomainName")
  valid_21626600 = validateParameter(valid_21626600, JString, required = true,
                                   default = nil)
  if valid_21626600 != nil:
    section.add "DomainName", valid_21626600
  var valid_21626601 = formData.getOrDefault("MultiAZ")
  valid_21626601 = validateParameter(valid_21626601, JBool, required = true,
                                   default = nil)
  if valid_21626601 != nil:
    section.add "MultiAZ", valid_21626601
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626602: Call_PostUpdateAvailabilityOptions_21626588;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_21626602.validator(path, query, header, formData, body, _)
  let scheme = call_21626602.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626602.makeUrl(scheme.get, call_21626602.host, call_21626602.base,
                               call_21626602.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626602, uri, valid, _)

proc call*(call_21626603: Call_PostUpdateAvailabilityOptions_21626588;
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
  var query_21626604 = newJObject()
  var formData_21626605 = newJObject()
  add(formData_21626605, "DomainName", newJString(DomainName))
  add(formData_21626605, "MultiAZ", newJBool(MultiAZ))
  add(query_21626604, "Action", newJString(Action))
  add(query_21626604, "Version", newJString(Version))
  result = call_21626603.call(nil, query_21626604, nil, formData_21626605, nil)

var postUpdateAvailabilityOptions* = Call_PostUpdateAvailabilityOptions_21626588(
    name: "postUpdateAvailabilityOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateAvailabilityOptions",
    validator: validate_PostUpdateAvailabilityOptions_21626589, base: "/",
    makeUrl: url_PostUpdateAvailabilityOptions_21626590,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateAvailabilityOptions_21626571 = ref object of OpenApiRestCall_21625435
proc url_GetUpdateAvailabilityOptions_21626573(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUpdateAvailabilityOptions_21626572(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626574 = query.getOrDefault("MultiAZ")
  valid_21626574 = validateParameter(valid_21626574, JBool, required = true,
                                   default = nil)
  if valid_21626574 != nil:
    section.add "MultiAZ", valid_21626574
  var valid_21626575 = query.getOrDefault("Action")
  valid_21626575 = validateParameter(valid_21626575, JString, required = true, default = newJString(
      "UpdateAvailabilityOptions"))
  if valid_21626575 != nil:
    section.add "Action", valid_21626575
  var valid_21626576 = query.getOrDefault("DomainName")
  valid_21626576 = validateParameter(valid_21626576, JString, required = true,
                                   default = nil)
  if valid_21626576 != nil:
    section.add "DomainName", valid_21626576
  var valid_21626577 = query.getOrDefault("Version")
  valid_21626577 = validateParameter(valid_21626577, JString, required = true,
                                   default = newJString("2011-02-01"))
  if valid_21626577 != nil:
    section.add "Version", valid_21626577
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
  var valid_21626578 = header.getOrDefault("X-Amz-Date")
  valid_21626578 = validateParameter(valid_21626578, JString, required = false,
                                   default = nil)
  if valid_21626578 != nil:
    section.add "X-Amz-Date", valid_21626578
  var valid_21626579 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626579 = validateParameter(valid_21626579, JString, required = false,
                                   default = nil)
  if valid_21626579 != nil:
    section.add "X-Amz-Security-Token", valid_21626579
  var valid_21626580 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626580 = validateParameter(valid_21626580, JString, required = false,
                                   default = nil)
  if valid_21626580 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626580
  var valid_21626581 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626581 = validateParameter(valid_21626581, JString, required = false,
                                   default = nil)
  if valid_21626581 != nil:
    section.add "X-Amz-Algorithm", valid_21626581
  var valid_21626582 = header.getOrDefault("X-Amz-Signature")
  valid_21626582 = validateParameter(valid_21626582, JString, required = false,
                                   default = nil)
  if valid_21626582 != nil:
    section.add "X-Amz-Signature", valid_21626582
  var valid_21626583 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626583 = validateParameter(valid_21626583, JString, required = false,
                                   default = nil)
  if valid_21626583 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626583
  var valid_21626584 = header.getOrDefault("X-Amz-Credential")
  valid_21626584 = validateParameter(valid_21626584, JString, required = false,
                                   default = nil)
  if valid_21626584 != nil:
    section.add "X-Amz-Credential", valid_21626584
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626585: Call_GetUpdateAvailabilityOptions_21626571;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ## 
  let valid = call_21626585.validator(path, query, header, formData, body, _)
  let scheme = call_21626585.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626585.makeUrl(scheme.get, call_21626585.host, call_21626585.base,
                               call_21626585.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626585, uri, valid, _)

proc call*(call_21626586: Call_GetUpdateAvailabilityOptions_21626571;
          MultiAZ: bool; DomainName: string;
          Action: string = "UpdateAvailabilityOptions";
          Version: string = "2011-02-01"): Recallable =
  ## getUpdateAvailabilityOptions
  ## Configures the availability options for a domain. Enabling the Multi-AZ option expands an Amazon CloudSearch domain to an additional Availability Zone in the same Region to increase fault tolerance in the event of a service disruption. Changes to the Multi-AZ option can take about half an hour to become active. For more information, see <a href="http://docs.aws.amazon.com/cloudsearch/latest/developerguide/configuring-availability-options.html" target="_blank">Configuring Availability Options</a> in the <i>Amazon CloudSearch Developer Guide</i>.
  ##   MultiAZ: bool (required)
  ##          : You expand an existing search domain to a second Availability Zone by setting the Multi-AZ option to true. Similarly, you can turn off the Multi-AZ option to downgrade the domain to a single Availability Zone by setting the Multi-AZ option to <code>false</code>. 
  ##   Action: string (required)
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_21626587 = newJObject()
  add(query_21626587, "MultiAZ", newJBool(MultiAZ))
  add(query_21626587, "Action", newJString(Action))
  add(query_21626587, "DomainName", newJString(DomainName))
  add(query_21626587, "Version", newJString(Version))
  result = call_21626586.call(nil, query_21626587, nil, nil, nil)

var getUpdateAvailabilityOptions* = Call_GetUpdateAvailabilityOptions_21626571(
    name: "getUpdateAvailabilityOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateAvailabilityOptions",
    validator: validate_GetUpdateAvailabilityOptions_21626572, base: "/",
    makeUrl: url_GetUpdateAvailabilityOptions_21626573,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateDefaultSearchField_21626623 = ref object of OpenApiRestCall_21625435
proc url_PostUpdateDefaultSearchField_21626625(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostUpdateDefaultSearchField_21626624(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626626 = query.getOrDefault("Action")
  valid_21626626 = validateParameter(valid_21626626, JString, required = true, default = newJString(
      "UpdateDefaultSearchField"))
  if valid_21626626 != nil:
    section.add "Action", valid_21626626
  var valid_21626627 = query.getOrDefault("Version")
  valid_21626627 = validateParameter(valid_21626627, JString, required = true,
                                   default = newJString("2011-02-01"))
  if valid_21626627 != nil:
    section.add "Version", valid_21626627
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
  var valid_21626628 = header.getOrDefault("X-Amz-Date")
  valid_21626628 = validateParameter(valid_21626628, JString, required = false,
                                   default = nil)
  if valid_21626628 != nil:
    section.add "X-Amz-Date", valid_21626628
  var valid_21626629 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626629 = validateParameter(valid_21626629, JString, required = false,
                                   default = nil)
  if valid_21626629 != nil:
    section.add "X-Amz-Security-Token", valid_21626629
  var valid_21626630 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626630 = validateParameter(valid_21626630, JString, required = false,
                                   default = nil)
  if valid_21626630 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626630
  var valid_21626631 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626631 = validateParameter(valid_21626631, JString, required = false,
                                   default = nil)
  if valid_21626631 != nil:
    section.add "X-Amz-Algorithm", valid_21626631
  var valid_21626632 = header.getOrDefault("X-Amz-Signature")
  valid_21626632 = validateParameter(valid_21626632, JString, required = false,
                                   default = nil)
  if valid_21626632 != nil:
    section.add "X-Amz-Signature", valid_21626632
  var valid_21626633 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626633 = validateParameter(valid_21626633, JString, required = false,
                                   default = nil)
  if valid_21626633 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626633
  var valid_21626634 = header.getOrDefault("X-Amz-Credential")
  valid_21626634 = validateParameter(valid_21626634, JString, required = false,
                                   default = nil)
  if valid_21626634 != nil:
    section.add "X-Amz-Credential", valid_21626634
  result.add "header", section
  ## parameters in `formData` object:
  ##   DefaultSearchField: JString (required)
  ##                     : The text field to search if the search request does not specify which field to search. The default search field is used when search terms are specified with the <code>q</code> parameter, or if a match expression specified with the <code>bq</code> parameter does not constrain the search to a particular field. The default is an empty string, which automatically searches all text fields.
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil, "formData argument is necessary due to required `DefaultSearchField` field"
  var valid_21626635 = formData.getOrDefault("DefaultSearchField")
  valid_21626635 = validateParameter(valid_21626635, JString, required = true,
                                   default = nil)
  if valid_21626635 != nil:
    section.add "DefaultSearchField", valid_21626635
  var valid_21626636 = formData.getOrDefault("DomainName")
  valid_21626636 = validateParameter(valid_21626636, JString, required = true,
                                   default = nil)
  if valid_21626636 != nil:
    section.add "DomainName", valid_21626636
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626637: Call_PostUpdateDefaultSearchField_21626623;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Configures the default search field for the search domain. The default search field is the text field that is searched when a search request does not specify which fields to search. By default, it is configured to include the contents of all of the domain's text fields. 
  ## 
  let valid = call_21626637.validator(path, query, header, formData, body, _)
  let scheme = call_21626637.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626637.makeUrl(scheme.get, call_21626637.host, call_21626637.base,
                               call_21626637.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626637, uri, valid, _)

proc call*(call_21626638: Call_PostUpdateDefaultSearchField_21626623;
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
  var query_21626639 = newJObject()
  var formData_21626640 = newJObject()
  add(formData_21626640, "DefaultSearchField", newJString(DefaultSearchField))
  add(formData_21626640, "DomainName", newJString(DomainName))
  add(query_21626639, "Action", newJString(Action))
  add(query_21626639, "Version", newJString(Version))
  result = call_21626638.call(nil, query_21626639, nil, formData_21626640, nil)

var postUpdateDefaultSearchField* = Call_PostUpdateDefaultSearchField_21626623(
    name: "postUpdateDefaultSearchField", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateDefaultSearchField",
    validator: validate_PostUpdateDefaultSearchField_21626624, base: "/",
    makeUrl: url_PostUpdateDefaultSearchField_21626625,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateDefaultSearchField_21626606 = ref object of OpenApiRestCall_21625435
proc url_GetUpdateDefaultSearchField_21626608(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUpdateDefaultSearchField_21626607(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626609 = query.getOrDefault("Action")
  valid_21626609 = validateParameter(valid_21626609, JString, required = true, default = newJString(
      "UpdateDefaultSearchField"))
  if valid_21626609 != nil:
    section.add "Action", valid_21626609
  var valid_21626610 = query.getOrDefault("DomainName")
  valid_21626610 = validateParameter(valid_21626610, JString, required = true,
                                   default = nil)
  if valid_21626610 != nil:
    section.add "DomainName", valid_21626610
  var valid_21626611 = query.getOrDefault("DefaultSearchField")
  valid_21626611 = validateParameter(valid_21626611, JString, required = true,
                                   default = nil)
  if valid_21626611 != nil:
    section.add "DefaultSearchField", valid_21626611
  var valid_21626612 = query.getOrDefault("Version")
  valid_21626612 = validateParameter(valid_21626612, JString, required = true,
                                   default = newJString("2011-02-01"))
  if valid_21626612 != nil:
    section.add "Version", valid_21626612
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
  var valid_21626613 = header.getOrDefault("X-Amz-Date")
  valid_21626613 = validateParameter(valid_21626613, JString, required = false,
                                   default = nil)
  if valid_21626613 != nil:
    section.add "X-Amz-Date", valid_21626613
  var valid_21626614 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626614 = validateParameter(valid_21626614, JString, required = false,
                                   default = nil)
  if valid_21626614 != nil:
    section.add "X-Amz-Security-Token", valid_21626614
  var valid_21626615 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626615 = validateParameter(valid_21626615, JString, required = false,
                                   default = nil)
  if valid_21626615 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626615
  var valid_21626616 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626616 = validateParameter(valid_21626616, JString, required = false,
                                   default = nil)
  if valid_21626616 != nil:
    section.add "X-Amz-Algorithm", valid_21626616
  var valid_21626617 = header.getOrDefault("X-Amz-Signature")
  valid_21626617 = validateParameter(valid_21626617, JString, required = false,
                                   default = nil)
  if valid_21626617 != nil:
    section.add "X-Amz-Signature", valid_21626617
  var valid_21626618 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626618 = validateParameter(valid_21626618, JString, required = false,
                                   default = nil)
  if valid_21626618 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626618
  var valid_21626619 = header.getOrDefault("X-Amz-Credential")
  valid_21626619 = validateParameter(valid_21626619, JString, required = false,
                                   default = nil)
  if valid_21626619 != nil:
    section.add "X-Amz-Credential", valid_21626619
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626620: Call_GetUpdateDefaultSearchField_21626606;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Configures the default search field for the search domain. The default search field is the text field that is searched when a search request does not specify which fields to search. By default, it is configured to include the contents of all of the domain's text fields. 
  ## 
  let valid = call_21626620.validator(path, query, header, formData, body, _)
  let scheme = call_21626620.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626620.makeUrl(scheme.get, call_21626620.host, call_21626620.base,
                               call_21626620.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626620, uri, valid, _)

proc call*(call_21626621: Call_GetUpdateDefaultSearchField_21626606;
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
  var query_21626622 = newJObject()
  add(query_21626622, "Action", newJString(Action))
  add(query_21626622, "DomainName", newJString(DomainName))
  add(query_21626622, "DefaultSearchField", newJString(DefaultSearchField))
  add(query_21626622, "Version", newJString(Version))
  result = call_21626621.call(nil, query_21626622, nil, nil, nil)

var getUpdateDefaultSearchField* = Call_GetUpdateDefaultSearchField_21626606(
    name: "getUpdateDefaultSearchField", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateDefaultSearchField",
    validator: validate_GetUpdateDefaultSearchField_21626607, base: "/",
    makeUrl: url_GetUpdateDefaultSearchField_21626608,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateServiceAccessPolicies_21626658 = ref object of OpenApiRestCall_21625435
proc url_PostUpdateServiceAccessPolicies_21626660(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostUpdateServiceAccessPolicies_21626659(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626661 = query.getOrDefault("Action")
  valid_21626661 = validateParameter(valid_21626661, JString, required = true, default = newJString(
      "UpdateServiceAccessPolicies"))
  if valid_21626661 != nil:
    section.add "Action", valid_21626661
  var valid_21626662 = query.getOrDefault("Version")
  valid_21626662 = validateParameter(valid_21626662, JString, required = true,
                                   default = newJString("2011-02-01"))
  if valid_21626662 != nil:
    section.add "Version", valid_21626662
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
  var valid_21626663 = header.getOrDefault("X-Amz-Date")
  valid_21626663 = validateParameter(valid_21626663, JString, required = false,
                                   default = nil)
  if valid_21626663 != nil:
    section.add "X-Amz-Date", valid_21626663
  var valid_21626664 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626664 = validateParameter(valid_21626664, JString, required = false,
                                   default = nil)
  if valid_21626664 != nil:
    section.add "X-Amz-Security-Token", valid_21626664
  var valid_21626665 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626665 = validateParameter(valid_21626665, JString, required = false,
                                   default = nil)
  if valid_21626665 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626665
  var valid_21626666 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626666 = validateParameter(valid_21626666, JString, required = false,
                                   default = nil)
  if valid_21626666 != nil:
    section.add "X-Amz-Algorithm", valid_21626666
  var valid_21626667 = header.getOrDefault("X-Amz-Signature")
  valid_21626667 = validateParameter(valid_21626667, JString, required = false,
                                   default = nil)
  if valid_21626667 != nil:
    section.add "X-Amz-Signature", valid_21626667
  var valid_21626668 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626668 = validateParameter(valid_21626668, JString, required = false,
                                   default = nil)
  if valid_21626668 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626668
  var valid_21626669 = header.getOrDefault("X-Amz-Credential")
  valid_21626669 = validateParameter(valid_21626669, JString, required = false,
                                   default = nil)
  if valid_21626669 != nil:
    section.add "X-Amz-Credential", valid_21626669
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
  var valid_21626670 = formData.getOrDefault("DomainName")
  valid_21626670 = validateParameter(valid_21626670, JString, required = true,
                                   default = nil)
  if valid_21626670 != nil:
    section.add "DomainName", valid_21626670
  var valid_21626671 = formData.getOrDefault("AccessPolicies")
  valid_21626671 = validateParameter(valid_21626671, JString, required = true,
                                   default = nil)
  if valid_21626671 != nil:
    section.add "AccessPolicies", valid_21626671
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626672: Call_PostUpdateServiceAccessPolicies_21626658;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Configures the policies that control access to the domain's document and search services. The maximum size of an access policy document is 100 KB.
  ## 
  let valid = call_21626672.validator(path, query, header, formData, body, _)
  let scheme = call_21626672.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626672.makeUrl(scheme.get, call_21626672.host, call_21626672.base,
                               call_21626672.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626672, uri, valid, _)

proc call*(call_21626673: Call_PostUpdateServiceAccessPolicies_21626658;
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
  var query_21626674 = newJObject()
  var formData_21626675 = newJObject()
  add(formData_21626675, "DomainName", newJString(DomainName))
  add(formData_21626675, "AccessPolicies", newJString(AccessPolicies))
  add(query_21626674, "Action", newJString(Action))
  add(query_21626674, "Version", newJString(Version))
  result = call_21626673.call(nil, query_21626674, nil, formData_21626675, nil)

var postUpdateServiceAccessPolicies* = Call_PostUpdateServiceAccessPolicies_21626658(
    name: "postUpdateServiceAccessPolicies", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateServiceAccessPolicies",
    validator: validate_PostUpdateServiceAccessPolicies_21626659, base: "/",
    makeUrl: url_PostUpdateServiceAccessPolicies_21626660,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateServiceAccessPolicies_21626641 = ref object of OpenApiRestCall_21625435
proc url_GetUpdateServiceAccessPolicies_21626643(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUpdateServiceAccessPolicies_21626642(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
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
  var valid_21626644 = query.getOrDefault("Action")
  valid_21626644 = validateParameter(valid_21626644, JString, required = true, default = newJString(
      "UpdateServiceAccessPolicies"))
  if valid_21626644 != nil:
    section.add "Action", valid_21626644
  var valid_21626645 = query.getOrDefault("AccessPolicies")
  valid_21626645 = validateParameter(valid_21626645, JString, required = true,
                                   default = nil)
  if valid_21626645 != nil:
    section.add "AccessPolicies", valid_21626645
  var valid_21626646 = query.getOrDefault("DomainName")
  valid_21626646 = validateParameter(valid_21626646, JString, required = true,
                                   default = nil)
  if valid_21626646 != nil:
    section.add "DomainName", valid_21626646
  var valid_21626647 = query.getOrDefault("Version")
  valid_21626647 = validateParameter(valid_21626647, JString, required = true,
                                   default = newJString("2011-02-01"))
  if valid_21626647 != nil:
    section.add "Version", valid_21626647
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
  var valid_21626648 = header.getOrDefault("X-Amz-Date")
  valid_21626648 = validateParameter(valid_21626648, JString, required = false,
                                   default = nil)
  if valid_21626648 != nil:
    section.add "X-Amz-Date", valid_21626648
  var valid_21626649 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626649 = validateParameter(valid_21626649, JString, required = false,
                                   default = nil)
  if valid_21626649 != nil:
    section.add "X-Amz-Security-Token", valid_21626649
  var valid_21626650 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626650 = validateParameter(valid_21626650, JString, required = false,
                                   default = nil)
  if valid_21626650 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626650
  var valid_21626651 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626651 = validateParameter(valid_21626651, JString, required = false,
                                   default = nil)
  if valid_21626651 != nil:
    section.add "X-Amz-Algorithm", valid_21626651
  var valid_21626652 = header.getOrDefault("X-Amz-Signature")
  valid_21626652 = validateParameter(valid_21626652, JString, required = false,
                                   default = nil)
  if valid_21626652 != nil:
    section.add "X-Amz-Signature", valid_21626652
  var valid_21626653 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626653 = validateParameter(valid_21626653, JString, required = false,
                                   default = nil)
  if valid_21626653 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626653
  var valid_21626654 = header.getOrDefault("X-Amz-Credential")
  valid_21626654 = validateParameter(valid_21626654, JString, required = false,
                                   default = nil)
  if valid_21626654 != nil:
    section.add "X-Amz-Credential", valid_21626654
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626655: Call_GetUpdateServiceAccessPolicies_21626641;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Configures the policies that control access to the domain's document and search services. The maximum size of an access policy document is 100 KB.
  ## 
  let valid = call_21626655.validator(path, query, header, formData, body, _)
  let scheme = call_21626655.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626655.makeUrl(scheme.get, call_21626655.host, call_21626655.base,
                               call_21626655.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626655, uri, valid, _)

proc call*(call_21626656: Call_GetUpdateServiceAccessPolicies_21626641;
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
  var query_21626657 = newJObject()
  add(query_21626657, "Action", newJString(Action))
  add(query_21626657, "AccessPolicies", newJString(AccessPolicies))
  add(query_21626657, "DomainName", newJString(DomainName))
  add(query_21626657, "Version", newJString(Version))
  result = call_21626656.call(nil, query_21626657, nil, nil, nil)

var getUpdateServiceAccessPolicies* = Call_GetUpdateServiceAccessPolicies_21626641(
    name: "getUpdateServiceAccessPolicies", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com",
    route: "/#Action=UpdateServiceAccessPolicies",
    validator: validate_GetUpdateServiceAccessPolicies_21626642, base: "/",
    makeUrl: url_GetUpdateServiceAccessPolicies_21626643,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateStemmingOptions_21626693 = ref object of OpenApiRestCall_21625435
proc url_PostUpdateStemmingOptions_21626695(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostUpdateStemmingOptions_21626694(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626696 = query.getOrDefault("Action")
  valid_21626696 = validateParameter(valid_21626696, JString, required = true, default = newJString(
      "UpdateStemmingOptions"))
  if valid_21626696 != nil:
    section.add "Action", valid_21626696
  var valid_21626697 = query.getOrDefault("Version")
  valid_21626697 = validateParameter(valid_21626697, JString, required = true,
                                   default = newJString("2011-02-01"))
  if valid_21626697 != nil:
    section.add "Version", valid_21626697
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
  var valid_21626698 = header.getOrDefault("X-Amz-Date")
  valid_21626698 = validateParameter(valid_21626698, JString, required = false,
                                   default = nil)
  if valid_21626698 != nil:
    section.add "X-Amz-Date", valid_21626698
  var valid_21626699 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626699 = validateParameter(valid_21626699, JString, required = false,
                                   default = nil)
  if valid_21626699 != nil:
    section.add "X-Amz-Security-Token", valid_21626699
  var valid_21626700 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626700 = validateParameter(valid_21626700, JString, required = false,
                                   default = nil)
  if valid_21626700 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626700
  var valid_21626701 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626701 = validateParameter(valid_21626701, JString, required = false,
                                   default = nil)
  if valid_21626701 != nil:
    section.add "X-Amz-Algorithm", valid_21626701
  var valid_21626702 = header.getOrDefault("X-Amz-Signature")
  valid_21626702 = validateParameter(valid_21626702, JString, required = false,
                                   default = nil)
  if valid_21626702 != nil:
    section.add "X-Amz-Signature", valid_21626702
  var valid_21626703 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626703 = validateParameter(valid_21626703, JString, required = false,
                                   default = nil)
  if valid_21626703 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626703
  var valid_21626704 = header.getOrDefault("X-Amz-Credential")
  valid_21626704 = validateParameter(valid_21626704, JString, required = false,
                                   default = nil)
  if valid_21626704 != nil:
    section.add "X-Amz-Credential", valid_21626704
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Stems: JString (required)
  ##        : Maps terms to their stems, serialized as a JSON document. The document has a single object with one property "stems" whose value is an object mapping terms to their stems. The maximum size of a stemming document is 500 KB. Example: <code>{ "stems": {"people": "person", "walking": "walk"} }</code>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_21626705 = formData.getOrDefault("DomainName")
  valid_21626705 = validateParameter(valid_21626705, JString, required = true,
                                   default = nil)
  if valid_21626705 != nil:
    section.add "DomainName", valid_21626705
  var valid_21626706 = formData.getOrDefault("Stems")
  valid_21626706 = validateParameter(valid_21626706, JString, required = true,
                                   default = nil)
  if valid_21626706 != nil:
    section.add "Stems", valid_21626706
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626707: Call_PostUpdateStemmingOptions_21626693;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Configures a stemming dictionary for the search domain. The stemming dictionary is used during indexing and when processing search requests. The maximum size of the stemming dictionary is 500 KB.
  ## 
  let valid = call_21626707.validator(path, query, header, formData, body, _)
  let scheme = call_21626707.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626707.makeUrl(scheme.get, call_21626707.host, call_21626707.base,
                               call_21626707.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626707, uri, valid, _)

proc call*(call_21626708: Call_PostUpdateStemmingOptions_21626693;
          DomainName: string; Stems: string;
          Action: string = "UpdateStemmingOptions"; Version: string = "2011-02-01"): Recallable =
  ## postUpdateStemmingOptions
  ## Configures a stemming dictionary for the search domain. The stemming dictionary is used during indexing and when processing search requests. The maximum size of the stemming dictionary is 500 KB.
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Stems: string (required)
  ##        : Maps terms to their stems, serialized as a JSON document. The document has a single object with one property "stems" whose value is an object mapping terms to their stems. The maximum size of a stemming document is 500 KB. Example: <code>{ "stems": {"people": "person", "walking": "walk"} }</code>
  ##   Version: string (required)
  var query_21626709 = newJObject()
  var formData_21626710 = newJObject()
  add(formData_21626710, "DomainName", newJString(DomainName))
  add(query_21626709, "Action", newJString(Action))
  add(formData_21626710, "Stems", newJString(Stems))
  add(query_21626709, "Version", newJString(Version))
  result = call_21626708.call(nil, query_21626709, nil, formData_21626710, nil)

var postUpdateStemmingOptions* = Call_PostUpdateStemmingOptions_21626693(
    name: "postUpdateStemmingOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateStemmingOptions",
    validator: validate_PostUpdateStemmingOptions_21626694, base: "/",
    makeUrl: url_PostUpdateStemmingOptions_21626695,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateStemmingOptions_21626676 = ref object of OpenApiRestCall_21625435
proc url_GetUpdateStemmingOptions_21626678(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUpdateStemmingOptions_21626677(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626679 = query.getOrDefault("Action")
  valid_21626679 = validateParameter(valid_21626679, JString, required = true, default = newJString(
      "UpdateStemmingOptions"))
  if valid_21626679 != nil:
    section.add "Action", valid_21626679
  var valid_21626680 = query.getOrDefault("Stems")
  valid_21626680 = validateParameter(valid_21626680, JString, required = true,
                                   default = nil)
  if valid_21626680 != nil:
    section.add "Stems", valid_21626680
  var valid_21626681 = query.getOrDefault("DomainName")
  valid_21626681 = validateParameter(valid_21626681, JString, required = true,
                                   default = nil)
  if valid_21626681 != nil:
    section.add "DomainName", valid_21626681
  var valid_21626682 = query.getOrDefault("Version")
  valid_21626682 = validateParameter(valid_21626682, JString, required = true,
                                   default = newJString("2011-02-01"))
  if valid_21626682 != nil:
    section.add "Version", valid_21626682
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
  var valid_21626683 = header.getOrDefault("X-Amz-Date")
  valid_21626683 = validateParameter(valid_21626683, JString, required = false,
                                   default = nil)
  if valid_21626683 != nil:
    section.add "X-Amz-Date", valid_21626683
  var valid_21626684 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626684 = validateParameter(valid_21626684, JString, required = false,
                                   default = nil)
  if valid_21626684 != nil:
    section.add "X-Amz-Security-Token", valid_21626684
  var valid_21626685 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626685 = validateParameter(valid_21626685, JString, required = false,
                                   default = nil)
  if valid_21626685 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626685
  var valid_21626686 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626686 = validateParameter(valid_21626686, JString, required = false,
                                   default = nil)
  if valid_21626686 != nil:
    section.add "X-Amz-Algorithm", valid_21626686
  var valid_21626687 = header.getOrDefault("X-Amz-Signature")
  valid_21626687 = validateParameter(valid_21626687, JString, required = false,
                                   default = nil)
  if valid_21626687 != nil:
    section.add "X-Amz-Signature", valid_21626687
  var valid_21626688 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626688 = validateParameter(valid_21626688, JString, required = false,
                                   default = nil)
  if valid_21626688 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626688
  var valid_21626689 = header.getOrDefault("X-Amz-Credential")
  valid_21626689 = validateParameter(valid_21626689, JString, required = false,
                                   default = nil)
  if valid_21626689 != nil:
    section.add "X-Amz-Credential", valid_21626689
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626690: Call_GetUpdateStemmingOptions_21626676;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Configures a stemming dictionary for the search domain. The stemming dictionary is used during indexing and when processing search requests. The maximum size of the stemming dictionary is 500 KB.
  ## 
  let valid = call_21626690.validator(path, query, header, formData, body, _)
  let scheme = call_21626690.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626690.makeUrl(scheme.get, call_21626690.host, call_21626690.base,
                               call_21626690.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626690, uri, valid, _)

proc call*(call_21626691: Call_GetUpdateStemmingOptions_21626676; Stems: string;
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
  var query_21626692 = newJObject()
  add(query_21626692, "Action", newJString(Action))
  add(query_21626692, "Stems", newJString(Stems))
  add(query_21626692, "DomainName", newJString(DomainName))
  add(query_21626692, "Version", newJString(Version))
  result = call_21626691.call(nil, query_21626692, nil, nil, nil)

var getUpdateStemmingOptions* = Call_GetUpdateStemmingOptions_21626676(
    name: "getUpdateStemmingOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateStemmingOptions",
    validator: validate_GetUpdateStemmingOptions_21626677, base: "/",
    makeUrl: url_GetUpdateStemmingOptions_21626678,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateStopwordOptions_21626728 = ref object of OpenApiRestCall_21625435
proc url_PostUpdateStopwordOptions_21626730(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostUpdateStopwordOptions_21626729(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626731 = query.getOrDefault("Action")
  valid_21626731 = validateParameter(valid_21626731, JString, required = true, default = newJString(
      "UpdateStopwordOptions"))
  if valid_21626731 != nil:
    section.add "Action", valid_21626731
  var valid_21626732 = query.getOrDefault("Version")
  valid_21626732 = validateParameter(valid_21626732, JString, required = true,
                                   default = newJString("2011-02-01"))
  if valid_21626732 != nil:
    section.add "Version", valid_21626732
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
  var valid_21626733 = header.getOrDefault("X-Amz-Date")
  valid_21626733 = validateParameter(valid_21626733, JString, required = false,
                                   default = nil)
  if valid_21626733 != nil:
    section.add "X-Amz-Date", valid_21626733
  var valid_21626734 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626734 = validateParameter(valid_21626734, JString, required = false,
                                   default = nil)
  if valid_21626734 != nil:
    section.add "X-Amz-Security-Token", valid_21626734
  var valid_21626735 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626735 = validateParameter(valid_21626735, JString, required = false,
                                   default = nil)
  if valid_21626735 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626735
  var valid_21626736 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626736 = validateParameter(valid_21626736, JString, required = false,
                                   default = nil)
  if valid_21626736 != nil:
    section.add "X-Amz-Algorithm", valid_21626736
  var valid_21626737 = header.getOrDefault("X-Amz-Signature")
  valid_21626737 = validateParameter(valid_21626737, JString, required = false,
                                   default = nil)
  if valid_21626737 != nil:
    section.add "X-Amz-Signature", valid_21626737
  var valid_21626738 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626738 = validateParameter(valid_21626738, JString, required = false,
                                   default = nil)
  if valid_21626738 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626738
  var valid_21626739 = header.getOrDefault("X-Amz-Credential")
  valid_21626739 = validateParameter(valid_21626739, JString, required = false,
                                   default = nil)
  if valid_21626739 != nil:
    section.add "X-Amz-Credential", valid_21626739
  result.add "header", section
  ## parameters in `formData` object:
  ##   Stopwords: JString (required)
  ##            : Lists stopwords serialized as a JSON document. The document has a single object with one property "stopwords" whose value is an array of strings. The maximum size of a stopwords document is 10 KB. Example: <code>{ "stopwords": ["a", "an", "the", "of"] }</code>
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `Stopwords` field"
  var valid_21626740 = formData.getOrDefault("Stopwords")
  valid_21626740 = validateParameter(valid_21626740, JString, required = true,
                                   default = nil)
  if valid_21626740 != nil:
    section.add "Stopwords", valid_21626740
  var valid_21626741 = formData.getOrDefault("DomainName")
  valid_21626741 = validateParameter(valid_21626741, JString, required = true,
                                   default = nil)
  if valid_21626741 != nil:
    section.add "DomainName", valid_21626741
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626742: Call_PostUpdateStopwordOptions_21626728;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Configures stopwords for the search domain. Stopwords are used during indexing and when processing search requests. The maximum size of the stopwords dictionary is 10 KB.
  ## 
  let valid = call_21626742.validator(path, query, header, formData, body, _)
  let scheme = call_21626742.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626742.makeUrl(scheme.get, call_21626742.host, call_21626742.base,
                               call_21626742.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626742, uri, valid, _)

proc call*(call_21626743: Call_PostUpdateStopwordOptions_21626728;
          Stopwords: string; DomainName: string;
          Action: string = "UpdateStopwordOptions"; Version: string = "2011-02-01"): Recallable =
  ## postUpdateStopwordOptions
  ## Configures stopwords for the search domain. Stopwords are used during indexing and when processing search requests. The maximum size of the stopwords dictionary is 10 KB.
  ##   Stopwords: string (required)
  ##            : Lists stopwords serialized as a JSON document. The document has a single object with one property "stopwords" whose value is an array of strings. The maximum size of a stopwords document is 10 KB. Example: <code>{ "stopwords": ["a", "an", "the", "of"] }</code>
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626744 = newJObject()
  var formData_21626745 = newJObject()
  add(formData_21626745, "Stopwords", newJString(Stopwords))
  add(formData_21626745, "DomainName", newJString(DomainName))
  add(query_21626744, "Action", newJString(Action))
  add(query_21626744, "Version", newJString(Version))
  result = call_21626743.call(nil, query_21626744, nil, formData_21626745, nil)

var postUpdateStopwordOptions* = Call_PostUpdateStopwordOptions_21626728(
    name: "postUpdateStopwordOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateStopwordOptions",
    validator: validate_PostUpdateStopwordOptions_21626729, base: "/",
    makeUrl: url_PostUpdateStopwordOptions_21626730,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateStopwordOptions_21626711 = ref object of OpenApiRestCall_21625435
proc url_GetUpdateStopwordOptions_21626713(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUpdateStopwordOptions_21626712(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626714 = query.getOrDefault("Action")
  valid_21626714 = validateParameter(valid_21626714, JString, required = true, default = newJString(
      "UpdateStopwordOptions"))
  if valid_21626714 != nil:
    section.add "Action", valid_21626714
  var valid_21626715 = query.getOrDefault("Stopwords")
  valid_21626715 = validateParameter(valid_21626715, JString, required = true,
                                   default = nil)
  if valid_21626715 != nil:
    section.add "Stopwords", valid_21626715
  var valid_21626716 = query.getOrDefault("DomainName")
  valid_21626716 = validateParameter(valid_21626716, JString, required = true,
                                   default = nil)
  if valid_21626716 != nil:
    section.add "DomainName", valid_21626716
  var valid_21626717 = query.getOrDefault("Version")
  valid_21626717 = validateParameter(valid_21626717, JString, required = true,
                                   default = newJString("2011-02-01"))
  if valid_21626717 != nil:
    section.add "Version", valid_21626717
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
  var valid_21626718 = header.getOrDefault("X-Amz-Date")
  valid_21626718 = validateParameter(valid_21626718, JString, required = false,
                                   default = nil)
  if valid_21626718 != nil:
    section.add "X-Amz-Date", valid_21626718
  var valid_21626719 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626719 = validateParameter(valid_21626719, JString, required = false,
                                   default = nil)
  if valid_21626719 != nil:
    section.add "X-Amz-Security-Token", valid_21626719
  var valid_21626720 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626720 = validateParameter(valid_21626720, JString, required = false,
                                   default = nil)
  if valid_21626720 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626720
  var valid_21626721 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626721 = validateParameter(valid_21626721, JString, required = false,
                                   default = nil)
  if valid_21626721 != nil:
    section.add "X-Amz-Algorithm", valid_21626721
  var valid_21626722 = header.getOrDefault("X-Amz-Signature")
  valid_21626722 = validateParameter(valid_21626722, JString, required = false,
                                   default = nil)
  if valid_21626722 != nil:
    section.add "X-Amz-Signature", valid_21626722
  var valid_21626723 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626723 = validateParameter(valid_21626723, JString, required = false,
                                   default = nil)
  if valid_21626723 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626723
  var valid_21626724 = header.getOrDefault("X-Amz-Credential")
  valid_21626724 = validateParameter(valid_21626724, JString, required = false,
                                   default = nil)
  if valid_21626724 != nil:
    section.add "X-Amz-Credential", valid_21626724
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626725: Call_GetUpdateStopwordOptions_21626711;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Configures stopwords for the search domain. Stopwords are used during indexing and when processing search requests. The maximum size of the stopwords dictionary is 10 KB.
  ## 
  let valid = call_21626725.validator(path, query, header, formData, body, _)
  let scheme = call_21626725.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626725.makeUrl(scheme.get, call_21626725.host, call_21626725.base,
                               call_21626725.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626725, uri, valid, _)

proc call*(call_21626726: Call_GetUpdateStopwordOptions_21626711;
          Stopwords: string; DomainName: string;
          Action: string = "UpdateStopwordOptions"; Version: string = "2011-02-01"): Recallable =
  ## getUpdateStopwordOptions
  ## Configures stopwords for the search domain. Stopwords are used during indexing and when processing search requests. The maximum size of the stopwords dictionary is 10 KB.
  ##   Action: string (required)
  ##   Stopwords: string (required)
  ##            : Lists stopwords serialized as a JSON document. The document has a single object with one property "stopwords" whose value is an array of strings. The maximum size of a stopwords document is 10 KB. Example: <code>{ "stopwords": ["a", "an", "the", "of"] }</code>
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Version: string (required)
  var query_21626727 = newJObject()
  add(query_21626727, "Action", newJString(Action))
  add(query_21626727, "Stopwords", newJString(Stopwords))
  add(query_21626727, "DomainName", newJString(DomainName))
  add(query_21626727, "Version", newJString(Version))
  result = call_21626726.call(nil, query_21626727, nil, nil, nil)

var getUpdateStopwordOptions* = Call_GetUpdateStopwordOptions_21626711(
    name: "getUpdateStopwordOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateStopwordOptions",
    validator: validate_GetUpdateStopwordOptions_21626712, base: "/",
    makeUrl: url_GetUpdateStopwordOptions_21626713,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PostUpdateSynonymOptions_21626763 = ref object of OpenApiRestCall_21625435
proc url_PostUpdateSynonymOptions_21626765(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PostUpdateSynonymOptions_21626764(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626766 = query.getOrDefault("Action")
  valid_21626766 = validateParameter(valid_21626766, JString, required = true,
                                   default = newJString("UpdateSynonymOptions"))
  if valid_21626766 != nil:
    section.add "Action", valid_21626766
  var valid_21626767 = query.getOrDefault("Version")
  valid_21626767 = validateParameter(valid_21626767, JString, required = true,
                                   default = newJString("2011-02-01"))
  if valid_21626767 != nil:
    section.add "Version", valid_21626767
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
  var valid_21626768 = header.getOrDefault("X-Amz-Date")
  valid_21626768 = validateParameter(valid_21626768, JString, required = false,
                                   default = nil)
  if valid_21626768 != nil:
    section.add "X-Amz-Date", valid_21626768
  var valid_21626769 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626769 = validateParameter(valid_21626769, JString, required = false,
                                   default = nil)
  if valid_21626769 != nil:
    section.add "X-Amz-Security-Token", valid_21626769
  var valid_21626770 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626770 = validateParameter(valid_21626770, JString, required = false,
                                   default = nil)
  if valid_21626770 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626770
  var valid_21626771 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626771 = validateParameter(valid_21626771, JString, required = false,
                                   default = nil)
  if valid_21626771 != nil:
    section.add "X-Amz-Algorithm", valid_21626771
  var valid_21626772 = header.getOrDefault("X-Amz-Signature")
  valid_21626772 = validateParameter(valid_21626772, JString, required = false,
                                   default = nil)
  if valid_21626772 != nil:
    section.add "X-Amz-Signature", valid_21626772
  var valid_21626773 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626773 = validateParameter(valid_21626773, JString, required = false,
                                   default = nil)
  if valid_21626773 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626773
  var valid_21626774 = header.getOrDefault("X-Amz-Credential")
  valid_21626774 = validateParameter(valid_21626774, JString, required = false,
                                   default = nil)
  if valid_21626774 != nil:
    section.add "X-Amz-Credential", valid_21626774
  result.add "header", section
  ## parameters in `formData` object:
  ##   DomainName: JString (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Synonyms: JString (required)
  ##           : Maps terms to their synonyms, serialized as a JSON document. The document has a single object with one property "synonyms" whose value is an object mapping terms to their synonyms. Each synonym is a simple string or an array of strings. The maximum size of a stopwords document is 100 KB. Example: <code>{ "synonyms": {"cat": ["feline", "kitten"], "puppy": "dog"} }</code>
  section = newJObject()
  assert formData != nil,
        "formData argument is necessary due to required `DomainName` field"
  var valid_21626775 = formData.getOrDefault("DomainName")
  valid_21626775 = validateParameter(valid_21626775, JString, required = true,
                                   default = nil)
  if valid_21626775 != nil:
    section.add "DomainName", valid_21626775
  var valid_21626776 = formData.getOrDefault("Synonyms")
  valid_21626776 = validateParameter(valid_21626776, JString, required = true,
                                   default = nil)
  if valid_21626776 != nil:
    section.add "Synonyms", valid_21626776
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626777: Call_PostUpdateSynonymOptions_21626763;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Configures a synonym dictionary for the search domain. The synonym dictionary is used during indexing to configure mappings for terms that occur in text fields. The maximum size of the synonym dictionary is 100 KB. 
  ## 
  let valid = call_21626777.validator(path, query, header, formData, body, _)
  let scheme = call_21626777.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626777.makeUrl(scheme.get, call_21626777.host, call_21626777.base,
                               call_21626777.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626777, uri, valid, _)

proc call*(call_21626778: Call_PostUpdateSynonymOptions_21626763;
          DomainName: string; Synonyms: string;
          Action: string = "UpdateSynonymOptions"; Version: string = "2011-02-01"): Recallable =
  ## postUpdateSynonymOptions
  ## Configures a synonym dictionary for the search domain. The synonym dictionary is used during indexing to configure mappings for terms that occur in text fields. The maximum size of the synonym dictionary is 100 KB. 
  ##   DomainName: string (required)
  ##             : A string that represents the name of a domain. Domain names must be unique across the domains owned by an account within an AWS region. Domain names must start with a letter or number and can contain the following characters: a-z (lowercase), 0-9, and - (hyphen). Uppercase letters and underscores are not allowed.
  ##   Synonyms: string (required)
  ##           : Maps terms to their synonyms, serialized as a JSON document. The document has a single object with one property "synonyms" whose value is an object mapping terms to their synonyms. Each synonym is a simple string or an array of strings. The maximum size of a stopwords document is 100 KB. Example: <code>{ "synonyms": {"cat": ["feline", "kitten"], "puppy": "dog"} }</code>
  ##   Action: string (required)
  ##   Version: string (required)
  var query_21626779 = newJObject()
  var formData_21626780 = newJObject()
  add(formData_21626780, "DomainName", newJString(DomainName))
  add(formData_21626780, "Synonyms", newJString(Synonyms))
  add(query_21626779, "Action", newJString(Action))
  add(query_21626779, "Version", newJString(Version))
  result = call_21626778.call(nil, query_21626779, nil, formData_21626780, nil)

var postUpdateSynonymOptions* = Call_PostUpdateSynonymOptions_21626763(
    name: "postUpdateSynonymOptions", meth: HttpMethod.HttpPost,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateSynonymOptions",
    validator: validate_PostUpdateSynonymOptions_21626764, base: "/",
    makeUrl: url_PostUpdateSynonymOptions_21626765,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetUpdateSynonymOptions_21626746 = ref object of OpenApiRestCall_21625435
proc url_GetUpdateSynonymOptions_21626748(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetUpdateSynonymOptions_21626747(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
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
  var valid_21626749 = query.getOrDefault("Action")
  valid_21626749 = validateParameter(valid_21626749, JString, required = true,
                                   default = newJString("UpdateSynonymOptions"))
  if valid_21626749 != nil:
    section.add "Action", valid_21626749
  var valid_21626750 = query.getOrDefault("Synonyms")
  valid_21626750 = validateParameter(valid_21626750, JString, required = true,
                                   default = nil)
  if valid_21626750 != nil:
    section.add "Synonyms", valid_21626750
  var valid_21626751 = query.getOrDefault("DomainName")
  valid_21626751 = validateParameter(valid_21626751, JString, required = true,
                                   default = nil)
  if valid_21626751 != nil:
    section.add "DomainName", valid_21626751
  var valid_21626752 = query.getOrDefault("Version")
  valid_21626752 = validateParameter(valid_21626752, JString, required = true,
                                   default = newJString("2011-02-01"))
  if valid_21626752 != nil:
    section.add "Version", valid_21626752
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
  var valid_21626753 = header.getOrDefault("X-Amz-Date")
  valid_21626753 = validateParameter(valid_21626753, JString, required = false,
                                   default = nil)
  if valid_21626753 != nil:
    section.add "X-Amz-Date", valid_21626753
  var valid_21626754 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626754 = validateParameter(valid_21626754, JString, required = false,
                                   default = nil)
  if valid_21626754 != nil:
    section.add "X-Amz-Security-Token", valid_21626754
  var valid_21626755 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626755 = validateParameter(valid_21626755, JString, required = false,
                                   default = nil)
  if valid_21626755 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626755
  var valid_21626756 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626756 = validateParameter(valid_21626756, JString, required = false,
                                   default = nil)
  if valid_21626756 != nil:
    section.add "X-Amz-Algorithm", valid_21626756
  var valid_21626757 = header.getOrDefault("X-Amz-Signature")
  valid_21626757 = validateParameter(valid_21626757, JString, required = false,
                                   default = nil)
  if valid_21626757 != nil:
    section.add "X-Amz-Signature", valid_21626757
  var valid_21626758 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626758 = validateParameter(valid_21626758, JString, required = false,
                                   default = nil)
  if valid_21626758 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626758
  var valid_21626759 = header.getOrDefault("X-Amz-Credential")
  valid_21626759 = validateParameter(valid_21626759, JString, required = false,
                                   default = nil)
  if valid_21626759 != nil:
    section.add "X-Amz-Credential", valid_21626759
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626760: Call_GetUpdateSynonymOptions_21626746;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Configures a synonym dictionary for the search domain. The synonym dictionary is used during indexing to configure mappings for terms that occur in text fields. The maximum size of the synonym dictionary is 100 KB. 
  ## 
  let valid = call_21626760.validator(path, query, header, formData, body, _)
  let scheme = call_21626760.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626760.makeUrl(scheme.get, call_21626760.host, call_21626760.base,
                               call_21626760.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626760, uri, valid, _)

proc call*(call_21626761: Call_GetUpdateSynonymOptions_21626746; Synonyms: string;
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
  var query_21626762 = newJObject()
  add(query_21626762, "Action", newJString(Action))
  add(query_21626762, "Synonyms", newJString(Synonyms))
  add(query_21626762, "DomainName", newJString(DomainName))
  add(query_21626762, "Version", newJString(Version))
  result = call_21626761.call(nil, query_21626762, nil, nil, nil)

var getUpdateSynonymOptions* = Call_GetUpdateSynonymOptions_21626746(
    name: "getUpdateSynonymOptions", meth: HttpMethod.HttpGet,
    host: "cloudsearch.amazonaws.com", route: "/#Action=UpdateSynonymOptions",
    validator: validate_GetUpdateSynonymOptions_21626747, base: "/",
    makeUrl: url_GetUpdateSynonymOptions_21626748,
    schemes: {Scheme.Https, Scheme.Http})
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
type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
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
  recall.headers[$ContentSha256] = hash(recall.body, SHA256)
  let
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

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body = ""): Recallable {.
    base.} =
  ## the hook is a terrible earworm
  var
    headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
    text = body
  if text.len == 0 and "body" in input:
    text = input.getOrDefault("body").getStr
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  else:
    headers["content-md5"] = base64.encode text.toMD5
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)

when not defined(ssl):
  {.error: "use ssl".}